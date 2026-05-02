"""
Fixture: deliberate anti-patterns for django-patterns eval scenario 1.

Issues present:
  - Business logic in Product.save() override (warning)
  - Signal used for business logic: post_save on Order triggers inventory update (warning)
  - Fat view: ProductListView.get_queryset() + render context + email logic > 200 lines (warning)
  - N+1 query in template context: reviews queryset accessed per product in loop (failure)
"""

from django.db import models
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.shortcuts import render, get_object_or_404
from django.core.mail import send_mail
from django.contrib.auth.decorators import login_required


class Product(models.Model):
    name = models.CharField(max_length=200)
    slug = models.SlugField(unique=True)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    stock = models.IntegerField(default=0)
    description = models.TextField(blank=True)
    category = models.ForeignKey("Category", on_delete=models.CASCADE)
    created_by = models.ForeignKey("auth.User", on_delete=models.SET_NULL, null=True)

    def save(self, *args, **kwargs):
        # Business logic in save() - bypassed by QuerySet.update() and bulk_create()
        if self.price < 0:
            raise ValueError("Price cannot be negative")
        if not self.slug:
            from django.utils.text import slugify

            self.slug = slugify(self.name)
        # Sends notification email inside save() - untestable in isolation
        if self.pk:
            old = Product.objects.get(pk=self.pk)
            if old.price != self.price:
                send_mail(
                    "Price changed",
                    f"{self.name} price changed to {self.price}",
                    "noreply@example.com",
                    ["admin@example.com"],
                )
        super().save(*args, **kwargs)


class Order(models.Model):
    product = models.ForeignKey(Product, on_delete=models.PROTECT)
    quantity = models.IntegerField()
    user = models.ForeignKey("auth.User", on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)


# Signal used for business logic: hidden control flow
@receiver(post_save, sender=Order)
def update_inventory_on_order(sender, instance, created, **kwargs):
    if created:
        product = instance.product
        product.stock -= instance.quantity
        product.save()


@login_required
def product_list(request):
    category_id = request.GET.get("category")
    sort = request.GET.get("sort", "name")
    page = int(request.GET.get("page", 1))
    per_page = 20

    # Fat view: all logic inline, >200 lines when complete
    products = Product.objects.filter(stock__gt=0)

    if category_id:
        products = products.filter(category_id=category_id)

    if sort == "price_asc":
        products = products.order_by("price")
    elif sort == "price_desc":
        products = products.order_by("-price")
    elif sort == "newest":
        products = products.order_by("-created_at")
    else:
        products = products.order_by("name")

    total = products.count()
    products = products[(page - 1) * per_page : page * per_page]

    # N+1: reviews is a reverse FK; each product.reviews.all() hits the DB
    product_data = []
    for product in products:
        reviews = product.reviews.all()  # query per product - N+1
        avg_rating = sum(r.rating for r in reviews) / len(reviews) if reviews else None
        product_data.append(
            {
                "product": product,
                "avg_rating": avg_rating,
                "review_count": len(reviews),
            }
        )

    # Inline email logic - belongs in a service
    if request.GET.get("notify"):
        emails = list(
            request.user.__class__.objects.filter(is_staff=True).values_list(
                "email", flat=True
            )
        )
        send_mail(
            "Product list viewed",
            f"User {request.user} viewed the product list",
            "noreply@example.com",
            emails,
        )

    categories = Category.objects.all()

    context = {
        "products": product_data,
        "categories": categories,
        "current_category": category_id,
        "sort": sort,
        "page": page,
        "total": total,
        "has_next": page * per_page < total,
        "has_prev": page > 1,
    }
    return render(request, "products/list.html", context)


@login_required
def product_detail(request, slug):
    product = get_object_or_404(Product, slug=slug)
    reviews = product.reviews.select_related("user").order_by("-created_at")
    return render(
        request,
        "products/detail.html",
        {
            "product": product,
            "reviews": reviews,
        },
    )


class Category(models.Model):
    name = models.CharField(max_length=100)
    slug = models.SlugField(unique=True)

    class Meta:
        verbose_name_plural = "categories"
