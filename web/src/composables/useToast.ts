import { ref } from 'vue';

const toastMessage = ref('');
const toastVisible = ref(false);
let timer: ReturnType<typeof setTimeout> | null = null;

export function useToast() {
  function showToast(message: string, duration = 1800) {
    toastMessage.value = message;
    toastVisible.value = true;
    if (timer) clearTimeout(timer);
    timer = setTimeout(() => {
      toastVisible.value = false;
    }, duration);
  }

  return {
    toastMessage,
    toastVisible,
    showToast,
  };
}
