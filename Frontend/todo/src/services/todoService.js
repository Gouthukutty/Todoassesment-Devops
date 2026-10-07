import axios from 'axios';

// The browser uses the same origin in production (/api).
// Local development can override this with REACT_APP_API_BASE_URL.
const API_BASE_URL = `${process.env.REACT_APP_API_BASE_URL || '/api'}/todos`;

const todoService = {
  getAllTodos: () => axios.get(API_BASE_URL),
  createTodo: (todo) => axios.post(API_BASE_URL, todo),
  updateTodo: (id, todo) => axios.put(`${API_BASE_URL}/${id}`, todo),
  deleteTodo: (id) => axios.delete(`${API_BASE_URL}/${id}`),
  summarizeTodos: () => axios.post(`${API_BASE_URL}/summarize`),
};

export default todoService;
