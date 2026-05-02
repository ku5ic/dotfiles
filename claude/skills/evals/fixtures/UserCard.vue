<script setup lang="ts">
import { reactive, computed } from "vue";

interface Tag {
  id: string;
  label: string;
}

interface User {
  id: string;
  name: string;
  bio: string;
  role: "admin" | "member";
  tags: Tag[];
}

const props = defineProps<{
  user: User;
  visibleTags: Tag[];
}>();

const state = reactive({
  expanded: false,
  draftBio: props.user.bio,
});

const { expanded, draftBio } = state;

const sortedTags = computed(() =>
  props.visibleTags.sort((a, b) => a.label.localeCompare(b.label)),
);

function promoteToAdmin() {
  props.user.role = "admin";
}
</script>

<template>
  <article>
    <header>
      <h2>{{ user.name }}</h2>
      <button @click="state.expanded = !state.expanded">
        {{ expanded ? "Collapse" : "Expand" }}
      </button>
    </header>

    <p v-html="user.bio"></p>

    <ul v-if="state.expanded">
      <li v-for="tag in sortedTags" v-if="tag.label">
        {{ tag.label }}
      </li>
    </ul>

    <footer>
      <input v-model="draftBio" />
      <button v-if="user.role !== 'admin'" @click="promoteToAdmin">
        Promote to admin
      </button>
    </footer>
  </article>
</template>
