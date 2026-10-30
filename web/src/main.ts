import { createApp } from 'vue'
import './style.css'
import App from './App.vue'

// Đảm bảo cố định chế độ sáng, loại bỏ thuộc tính theme tối cũ
document.documentElement.removeAttribute('data-theme');

createApp(App).mount('#app')
