require('dotenv').config();
const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { initDatabase, users, tasks, taskWorkers, notifications } = require('./database');

const app = express();
const PORT = process.env.PORT || 5000;
const JWT_SECRET = process.env.JWT_SECRET || 'your_secret_key_change_this_in_production_12345';

console.log('=== 서버 시작 ===');
console.log('PORT:', PORT);
console.log('JWT_SECRET:', JWT_SECRET ? '설정됨 ✅' : '설정 안됨 ❌');

// 미들웨어
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true
}));
app.use(express.json());
app.use('/download', express.static('public'));

// 데이터베이스 초기화
initDatabase();

// JWT 인증 미들웨어
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: '인증 토큰이 필요합니다' });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: '유효하지 않은 토큰입니다' });
    }
    req.user = user;
    next();
  });
}

// ==================== 인증 API ====================

// 회원가입
app.post('/api/register', async (req, res) => {
  try {
    console.log('=== 회원가입 요청 시작 ===');
    const { name, phone, birthdate, password } = req.body;
    console.log('요청 데이터:', { name, phone, birthdate, password: password ? '***' : undefined });

    if (!name || !phone || !birthdate || !password) {
      console.log('❌ 필수 필드 누락');
      return res.status(400).json({ error: '모든 필드를 입력해주세요' });
    }

    // 전화번호 중복 확인
    console.log('전화번호 중복 확인:', phone);
    const existingUser = users.getByPhone(phone);
    if (existingUser) {
      console.log('❌ 이미 등록된 전화번호:', phone);
      return res.status(400).json({ error: '이미 등록된 전화번호입니다' });
    }

    // 비밀번호 해시
    console.log('비밀번호 해시 생성 중...');
    const hashedPassword = await bcrypt.hash(password, 10);
    console.log('✅ 해시 생성 완료:', hashedPassword);

    // 사용자 추가
    console.log('사용자 데이터베이스에 추가 중...');
    const newUser = users.insert({
      name,
      phone,
      birthdate,
      password: hashedPassword
    });
    console.log('✅ 사용자 추가 완료:', { id: newUser.id, name: newUser.name, phone: newUser.phone });

    res.status(201).json({
      message: '회원가입이 완료되었습니다',
      userId: newUser.id
    });
  } catch (error) {
    console.error('❌ 회원가입 오류:', error);
    console.error('에러 스택:', error.stack);
    res.status(500).json({ error: '서버 오류가 발생했습니다' });
  }
});

// 로그인
app.post('/api/login', async (req, res) => {
  try {
    console.log('=== 로그인 요청 시작 ===');
    const { phone, password } = req.body;
    console.log('요청 데이터:', { phone, password: password ? '***' : undefined });

    if (!phone || !password) {
      console.log('❌ 필수 필드 누락');
      return res.status(400).json({ error: '전화번호와 비밀번호를 입력해주세요' });
    }

    console.log('사용자 조회 중:', phone);
    const user = users.getByPhone(phone);
    if (!user) {
      console.log('❌ 사용자를 찾을 수 없음:', phone);
      return res.status(401).json({ error: '전화번호 또는 비밀번호가 잘못되었습니다' });
    }

    console.log('✅ 사용자 발견:', { id: user.id, name: user.name, phone: user.phone });
    console.log('비밀번호 비교 중...');
    console.log('입력된 비밀번호:', password);
    console.log('저장된 해시:', user.password);

    const validPassword = await bcrypt.compare(password, user.password);
    console.log('비밀번호 검증 결과:', validPassword);

    if (!validPassword) {
      console.log('❌ 비밀번호 불일치');
      return res.status(401).json({ error: '전화번호 또는 비밀번호가 잘못되었습니다' });
    }

    console.log('JWT 토큰 생성 중...');
    const token = jwt.sign(
      { id: user.id, phone: user.phone, isAdmin: user.is_admin },
      JWT_SECRET,
      { expiresIn: '7d' }
    );
    console.log('✅ 토큰 생성 완료');

    console.log('✅ 로그인 성공!');
    res.json({
      token,
      user: {
        id: user.id,
        name: user.name,
        phone: user.phone,
        birthdate: user.birthdate,
        isAdmin: user.is_admin
      }
    });
  } catch (error) {
    console.error('❌ 로그인 오류:', error);
    console.error('에러 스택:', error.stack);
    res.status(500).json({ error: '서버 오류가 발생했습니다' });
  }
});

// ==================== 사용자 API ====================

// 모든 사용자 조회
app.get('/api/users', authenticateToken, (req, res) => {
  try {
    const allUsers = users.getAll().map(u => ({
      id: u.id,
      name: u.name,
      phone: u.phone,
      birthdate: u.birthdate
    }));
    res.json(allUsers);
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({ error: '서버 오류가 발생했습니다' });
  }
});

// 특정 사용자 조회
app.get('/api/users/:id', authenticateToken, (req, res) => {
  try {
    const user = users.getById(req.params.id);
    if (!user) {
      return res.status(404).json({ error: '사용자를 찾을 수 없습니다' });
    }

    res.json({
      id: user.id,
      name: user.name,
      phone: user.phone,
      birthdate: user.birthdate,
      is_admin: user.is_admin
    });
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({ error: '서버 오류가 발생했습니다' });
  }
});

// ==================== 작업 API ====================

// 작업 목록 조회
app.get('/api/tasks', authenticateToken, (req, res) => {
  try {
    const { status } = req.query;
    const allTasks = tasks.getAll(status);

    // 각 작업의 작업자 정보 추가
    const tasksWithWorkers = allTasks.map(task => {
      const workers = taskWorkers.getByTaskId(task.id);
      return { ...task, workers };
    });

    res.json(tasksWithWorkers);
  } catch (error) {
    console.error('Get tasks error:', error);
    res.status(500).json({ error: '서버 오류가 발생했습니다' });
  }
});

// 작업 상세 조회
app.get('/api/tasks/:id', authenticateToken, (req, res) => {
  try {
    const task = tasks.getById(req.params.id);
    if (!task) {
      return res.status(404).json({ error: '작업을 찾을 수 없습니다' });
    }

    // 작업자 정보 추가
    const workers = taskWorkers.getByTaskId(task.id);
    res.json({ ...task, workers });
  } catch (error) {
    console.error('Get task error:', error);
    res.status(500).json({ error: '서버 오류가 발생했습니다' });
  }
});

// 작업 생성
app.post('/api/tasks', authenticateToken, (req, res) => {
  try {
    console.log('=== 작업 생성 요청 시작 ===');
    console.log('요청 데이터:', req.body);

    const { title, description, priority, deadline, deadline_date, workerIds, worker_ids } = req.body;

    // deadline과 deadline_date 둘 다 허용
    const finalDeadline = deadline || deadline_date;
    // workerIds와 worker_ids 둘 다 허용
    const finalWorkerIds = workerIds || worker_ids || [];

    console.log('파싱된 데이터:', { title, description, priority, deadline: finalDeadline, workerIds: finalWorkerIds });

    if (!title || !priority) {
      console.log('❌ 필수 필드 누락');
      return res.status(400).json({ error: '제목과 우선순위는 필수입니다' });
    }

    // 작업 생성
    console.log('작업 데이터베이스에 추가 중...');
    const newTask = tasks.insert({
      title,
      description: description || '',
      priority,
      deadline_date: finalDeadline,
      creator_id: req.user.id
    });
    console.log('✅ 작업 생성 완료:', { id: newTask.id, title: newTask.title });

    // 작업자 추가
    if (finalWorkerIds && finalWorkerIds.length > 0) {
      console.log('작업자 추가 중:', finalWorkerIds);
      finalWorkerIds.forEach(workerId => {
        taskWorkers.insert(newTask.id, workerId);

        // 작업자에게 알림 생성
        notifications.insert({
          user_id: workerId,
          task_id: newTask.id,
          type: 'task_assigned',
          message: `새로운 작업이 할당되었습니다: ${title}`
        });
      });
      console.log('✅ 작업자 추가 완료');
    } else {
      console.log('⚠️ 작업자 없음 - 작업만 생성됨');
    }

    console.log('✅ 작업 생성 성공!');
    res.status(201).json({
      message: '작업이 생성되었습니다',
      taskId: newTask.id
    });
  } catch (error) {
    console.error('❌ 작업 생성 오류:', error);
    console.error('에러 스택:', error.stack);
    res.status(500).json({ error: '서버 오류가 발생했습니다' });
  }
});

// 작업 완료
app.put('/api/tasks/:id/complete', authenticateToken, (req, res) => {
  try {
    const taskId = req.params.id;
    const task = tasks.getById(taskId);

    if (!task) {
      return res.status(404).json({ error: '작업을 찾을 수 없습니다' });
    }

    // 작업 완료 처리
    tasks.update(taskId, {
      status: 'completed',
      completer_id: req.user.id,
      completed_date: new Date().toISOString().split('T')[0]
    });

    // 작업자들에게 알림
    const workers = taskWorkers.getByTaskId(taskId);
    workers.forEach(worker => {
      notifications.insert({
        user_id: worker.id,
        task_id: taskId,
        type: 'task_completed',
        message: `작업이 완료되었습니다: ${task.title}`
      });
    });

    res.json({ message: '작업이 완료되었습니다' });
  } catch (error) {
    console.error('Complete task error:', error);
    res.status(500).json({ error: '서버 오류가 발생했습니다' });
  }
});

// 작업 수정
app.put('/api/tasks/:id', authenticateToken, (req, res) => {
  try {
    const { title, description, priority, deadline_date, status, worker_ids } = req.body;
    const taskId = req.params.id;

    const task = tasks.getById(taskId);
    if (!task) {
      return res.status(404).json({ error: '작업을 찾을 수 없습니다' });
    }

    // 작업 정보 수정
    tasks.update(taskId, {
      title,
      description: description || '',
      priority,
      deadline_date,
      status: status || task.status
    });

    // 기존 작업자 삭제
    taskWorkers.deleteByTaskId(taskId);

    // 새 작업자 추가
    if (worker_ids && worker_ids.length > 0) {
      worker_ids.forEach(workerId => {
        taskWorkers.insert(taskId, workerId);
      });
    }

    res.json({ message: '작업이 수정되었습니다' });
  } catch (error) {
    console.error('Update task error:', error);
    res.status(500).json({ error: '서버 오류가 발생했습니다' });
  }
});

// 작업 삭제
app.delete('/api/tasks/:id', authenticateToken, (req, res) => {
  try {
    const task = tasks.getById(req.params.id);
    if (!task) {
      return res.status(404).json({ error: '작업을 찾을 수 없습니다' });
    }

    tasks.delete(req.params.id);
    res.json({ message: '작업이 삭제되었습니다' });
  } catch (error) {
    console.error('Delete task error:', error);
    res.status(500).json({ error: '서버 오류가 발생했습니다' });
  }
});

// ==================== 알림 API ====================

// 사용자 알림 조회
app.get('/api/notifications', authenticateToken, (req, res) => {
  try {
    const userNotifs = notifications.getByUserId(req.user.id);
    const notificationsWithTasks = userNotifs.map(n => {
      const task = tasks.getById(n.task_id);
      return {
        ...n,
        task_title: task ? task.title : null
      };
    });

    res.json(notificationsWithTasks);
  } catch (error) {
    console.error('Get notifications error:', error);
    res.status(500).json({ error: '서버 오류가 발생했습니다' });
  }
});

// 알림 읽음 처리
app.put('/api/notifications/:id/read', authenticateToken, (req, res) => {
  try {
    notifications.markAsRead(req.params.id, req.user.id);
    res.json({ message: '알림을 읽음 처리했습니다' });
  } catch (error) {
    console.error('Mark notification read error:', error);
    res.status(500).json({ error: '서버 오류가 발생했습니다' });
  }
});

// 독촉 기능
app.post('/api/tasks/:id/nudge', authenticateToken, (req, res) => {
  try {
    const taskId = req.params.id;
    const task = tasks.getById(taskId);

    if (!task) {
      return res.status(404).json({ error: '작업을 찾을 수 없습니다' });
    }

    // 작업자들에게 독촉 알림
    const workers = taskWorkers.getByTaskId(taskId);
    workers.forEach(worker => {
      notifications.insert({
        user_id: worker.id,
        task_id: taskId,
        type: 'nudge',
        message: `작업 독촉: ${task.title}`
      });
    });

    res.json({ message: '독촉 알림을 보냈습니다' });
  } catch (error) {
    console.error('Nudge error:', error);
    res.status(500).json({ error: '서버 오류가 발생했습니다' });
  }
});

// 테스트용 엔드포인트
app.get('/', (req, res) => {
  res.json({
    message: '협업 체크리스트 API 서버',
    version: '1.0.0',
    endpoints: [
      'POST /api/register',
      'POST /api/login',
      'GET /api/users',
      'GET /api/tasks',
      'POST /api/tasks',
      'PUT /api/tasks/:id/complete',
      'GET /api/notifications'
    ]
  });
});

// ==================== 서버 시작 ====================

app.listen(PORT, () => {
  console.log(`✅ Server is running on http://localhost:${PORT}`);
  console.log(`✅ API 테스트: http://localhost:${PORT}/`);
});
