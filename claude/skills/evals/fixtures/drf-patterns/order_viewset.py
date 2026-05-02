"""
Fixture: deliberate anti-patterns for drf-patterns eval scenario 1.

Issues present:
  - OrderSerializer uses fields = "__all__" (warning: leaks columns)
  - OrderViewSet has no permission_classes (failure on write endpoints)
  - get_queryset uses queryset.filter(**request.query_params) (failure: information disclosure)
  - ObtainTokenView has no throttle_classes (warning: credential stuffing)
  - No pagination configured (failure: unbounded list endpoint)
"""

from rest_framework import serializers, viewsets, status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.authtoken.models import Token
from django.contrib.auth import authenticate
from .models import Order


class OrderSerializer(serializers.ModelSerializer):
    class Meta:
        model = Order
        fields = "__all__"  # warning: exposes all columns including internal ones


class OrderViewSet(viewsets.ModelViewSet):
    # failure: no permission_classes - defaults to AllowAny
    serializer_class = OrderSerializer

    def get_queryset(self):
        # failure: passes raw query params to ORM filter
        # clients can filter on any field, including internal/sensitive ones
        return Order.objects.filter(**self.request.query_params.dict())


class ObtainTokenView(APIView):
    # warning: no throttle_classes on token endpoint
    # vulnerable to credential stuffing

    def post(self, request):
        username = request.data.get("username")
        password = request.data.get("password")
        user = authenticate(username=username, password=password)
        if user:
            token, _ = Token.objects.get_or_create(user=user)
            return Response({"token": token.key})
        return Response(
            {"error": "Invalid credentials"},
            status=status.HTTP_401_UNAUTHORIZED,
        )


class OrderStatusViewSet(viewsets.ReadOnlyModelViewSet):
    # warning: no explicit ordering_fields, uses OrderingFilter without restriction
    serializer_class = OrderSerializer
    filter_backends = ["rest_framework.filters.OrderingFilter"]
    # ordering_fields not set - exposes all model fields to ordering
