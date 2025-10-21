const fs = require('fs');
const path = require('path');

const DB_DIR = path.join(__dirname, 'data');
const USERS_FILE = path.join(DB_DIR, 'users.json');
const TASKS_FILE = path.join(DB_DIR, 'tasks.json');
const TASK_WORKERS_FILE = path.join(DB_DIR, 'task_workers.json');
const NOTIFICATIONS_FILE = path.join(DB_DIR, 'notifications.json');

// 데이터베이스 초기화
function initDatabase() {
  // data 디렉토리 생성
  if (!fs.existsSync(DB_DIR)) {
    fs.mkdirSync(DB_DIR, { recursive: true });
  }

  // JSON 파일 초기화
  if (!fs.existsSync(USERS_FILE)) {
    fs.writeFileSync(USERS_FILE, JSON.stringify([], null, 2));
  }
  if (!fs.existsSync(TASKS_FILE)) {
    fs.writeFileSync(TASKS_FILE, JSON.stringify([], null, 2));
  }
  if (!fs.existsSync(TASK_WORKERS_FILE)) {
    fs.writeFileSync(TASK_WORKERS_FILE, JSON.stringify([], null, 2));
  }
  if (!fs.existsSync(NOTIFICATIONS_FILE)) {
    fs.writeFileSync(NOTIFICATIONS_FILE, JSON.stringify([], null, 2));
  }

  console.log('Database initialized successfully');
}

// 데이터 읽기
function readData(file) {
  try {
    const data = fs.readFileSync(file, 'utf8');
    return JSON.parse(data);
  } catch (error) {
    return [];
  }
}

// 데이터 쓰기
function writeData(file, data) {
  fs.writeFileSync(file, JSON.stringify(data, null, 2));
}

// ID 생성
function getNextId(file) {
  const data = readData(file);
  if (data.length === 0) return 1;
  return Math.max(...data.map(item => item.id)) + 1;
}

// Users 테이블 메서드
const users = {
  getAll: () => readData(USERS_FILE),

  getById: (id) => {
    const data = readData(USERS_FILE);
    return data.find(u => u.id === parseInt(id));
  },

  getByPhone: (phone) => {
    const data = readData(USERS_FILE);
    return data.find(u => u.phone === phone);
  },

  insert: (user) => {
    const data = readData(USERS_FILE);
    const newUser = {
      id: getNextId(USERS_FILE),
      ...user,
      is_admin: user.is_admin || 0,
      created_at: new Date().toISOString()
    };
    data.push(newUser);
    writeData(USERS_FILE, data);
    return newUser;
  }
};

// Tasks 테이블 메서드
const tasks = {
  getAll: (status = null) => {
    let data = readData(TASKS_FILE);
    if (status && status !== 'all') {
      data = data.filter(t => t.status === status);
    }
    return data.map(task => {
      const creator = users.getById(task.creator_id);
      const completer = task.completer_id ? users.getById(task.completer_id) : null;
      return {
        ...task,
        creator_name: creator ? creator.name : null,
        completer_name: completer ? completer.name : null
      };
    });
  },

  getById: (id) => {
    const data = readData(TASKS_FILE);
    const task = data.find(t => t.id === parseInt(id));
    if (!task) return null;

    const creator = users.getById(task.creator_id);
    const completer = task.completer_id ? users.getById(task.completer_id) : null;
    return {
      ...task,
      creator_name: creator ? creator.name : null,
      completer_name: completer ? completer.name : null
    };
  },

  insert: (task) => {
    const data = readData(TASKS_FILE);
    const newTask = {
      id: getNextId(TASKS_FILE),
      ...task,
      status: 'in_progress',
      created_date: new Date().toISOString().split('T')[0],
      completer_id: null,
      completed_date: null
    };
    data.push(newTask);
    writeData(TASKS_FILE, data);
    return newTask;
  },

  update: (id, updates) => {
    const data = readData(TASKS_FILE);
    const index = data.findIndex(t => t.id === parseInt(id));
    if (index === -1) return null;

    data[index] = { ...data[index], ...updates };
    writeData(TASKS_FILE, data);
    return data[index];
  },

  delete: (id) => {
    const data = readData(TASKS_FILE);
    const filtered = data.filter(t => t.id !== parseInt(id));
    writeData(TASKS_FILE, filtered);

    // 관련 task_workers 삭제
    const workers = readData(TASK_WORKERS_FILE);
    const filteredWorkers = workers.filter(w => w.task_id !== parseInt(id));
    writeData(TASK_WORKERS_FILE, filteredWorkers);

    // 관련 notifications 삭제
    const notifs = readData(NOTIFICATIONS_FILE);
    const filteredNotifs = notifs.filter(n => n.task_id !== parseInt(id));
    writeData(NOTIFICATIONS_FILE, filteredNotifs);
  }
};

// Task Workers 테이블 메서드
const taskWorkers = {
  getByTaskId: (taskId) => {
    const data = readData(TASK_WORKERS_FILE);
    const workers = data.filter(tw => tw.task_id === parseInt(taskId));
    return workers.map(w => {
      const user = users.getById(w.worker_id);
      return user ? { id: user.id, name: user.name, phone: user.phone } : null;
    }).filter(Boolean);
  },

  insert: (taskId, workerId) => {
    const data = readData(TASK_WORKERS_FILE);
    // 중복 체크
    const exists = data.find(tw => tw.task_id === parseInt(taskId) && tw.worker_id === parseInt(workerId));
    if (exists) return exists;

    const newWorker = {
      id: getNextId(TASK_WORKERS_FILE),
      task_id: parseInt(taskId),
      worker_id: parseInt(workerId)
    };
    data.push(newWorker);
    writeData(TASK_WORKERS_FILE, data);
    return newWorker;
  },

  deleteByTaskId: (taskId) => {
    const data = readData(TASK_WORKERS_FILE);
    const filtered = data.filter(tw => tw.task_id !== parseInt(taskId));
    writeData(TASK_WORKERS_FILE, filtered);
  }
};

// Notifications 테이블 메서드
const notifications = {
  getByUserId: (userId) => {
    const data = readData(NOTIFICATIONS_FILE);
    return data.filter(n => n.user_id === parseInt(userId))
      .sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
      .slice(0, 50);
  },

  insert: (notification) => {
    const data = readData(NOTIFICATIONS_FILE);
    const newNotif = {
      id: getNextId(NOTIFICATIONS_FILE),
      ...notification,
      is_read: 0,
      created_at: new Date().toISOString()
    };
    data.push(newNotif);
    writeData(NOTIFICATIONS_FILE, data);
    return newNotif;
  },

  markAsRead: (id, userId) => {
    const data = readData(NOTIFICATIONS_FILE);
    const index = data.findIndex(n => n.id === parseInt(id) && n.user_id === parseInt(userId));
    if (index === -1) return null;

    data[index].is_read = 1;
    writeData(NOTIFICATIONS_FILE, data);
    return data[index];
  }
};

module.exports = {
  initDatabase,
  users,
  tasks,
  taskWorkers,
  notifications
};
