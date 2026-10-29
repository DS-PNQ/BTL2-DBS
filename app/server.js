// Ứng dụng web minh họa (phần 3): Express + mysql2, mọi thao tác ghi đều gọi thủ tục 2.1
const express = require('express');
const mysql = require('mysql2/promise');

const db = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'booking_db',
  dateStrings: true,
  charset: 'utf8mb4',
});

const app = express();
app.use(express.json());
app.use(express.static(`${__dirname}/public`));

// '' / undefined từ form -> NULL cho thủ tục
const val = (v) => (v === '' || v === undefined ? null : v);
const run = async (sql, params = []) => (await db.query(sql, params.map(val)))[0];

app.get('/api/lookups', async (req, res) => {
  const [guests, accommodations, rates] = await Promise.all([
    run('SELECT u.USER_ID, u.FULL_NAME, u.EMAIL FROM GUEST g JOIN `USER` u ON u.USER_ID = g.USER_ID ORDER BY u.FULL_NAME'),
    run('SELECT ACCOMMODATION_ID, NAME, CITY FROM ACCOMMODATION ORDER BY NAME'),
    run(`SELECT r.ACCOMMODATION_ID, r.ROOM_NAME, r.ROOM_RATE_ID, r.UNIT_PRICE, r.BREAKFAST_INCLUDED,
                r.FREE_CANCELLATION, r.EFFECTIVE_DATE, t.ADULTS, t.CHILDREN
         FROM ROOM_RATE r JOIN ROOM_TYPE t ON t.ACCOMMODATION_ID = r.ACCOMMODATION_ID AND t.ROOM_NAME = r.ROOM_NAME
         ORDER BY r.ACCOMMODATION_ID, r.ROOM_NAME, r.UNIT_PRICE`),
  ]);
  res.json({ guests, accommodations, rates });
});

// 3.2 danh sách: gọi thủ tục 2.3a
app.get('/api/bookings', async (req, res) => {
  const q = req.query;
  const [rows] = await run('CALL sp_search_bookings(?, ?, ?, ?, ?)', [q.keyword, q.city, q.status, q.from, q.to]);
  res.json(rows);
});

// 3.1 thêm / sửa / xóa: gọi thủ tục 2.1
app.post('/api/bookings', async (req, res) => {
  const b = req.body;
  await run('CALL sp_insert_booking(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, @new_id)', [
    b.userId, b.accommodationId, b.roomName, b.roomRateId, b.quantity,
    b.checkIn, b.checkOut, b.adults, b.children, b.eta, b.requests,
  ]);
  res.status(201).json({ ok: true });
});

app.put('/api/bookings/:id', async (req, res) => {
  const b = req.body;
  await db.query('CALL sp_update_booking(?, ?, ?, ?, ?, ?, ?, ?, ?)', [
    ...[req.params.id, b.checkIn, b.checkOut, b.adults, b.children, b.eta].map(val),
    b.requests ?? null,                       // '' = xóa yêu cầu đặc biệt, NULL = giữ nguyên
    ...[b.status, b.cancelReason].map(val),
  ]);
  res.json({ ok: true });
});

app.delete('/api/bookings/:id', async (req, res) => {
  await run('CALL sp_delete_booking(?)', [req.params.id]);
  res.json({ ok: true });
});

// 3.3 thủ tục 2.3b và các hàm 2.4
app.get('/api/revenue', async (req, res) => {
  const q = req.query;
  const [rows] = await run('CALL sp_revenue_by_accommodation(?, ?, ?, ?)', [q.city, q.from, q.to, q.minRevenue]);
  res.json(rows);
});

app.get('/api/occupancy', async (req, res) => {
  const q = req.query;
  const [row] = await run('SELECT fn_occupancy_rate(?, ?, ?) AS rate', [q.accommodationId, q.from, q.to]);
  res.json(row);
});

app.get('/api/bookings/:id/refund', async (req, res) => {
  const [row] = await run(
    `SELECT fn_refund_amount(?, CURDATE()) AS refund,
            (SELECT AMOUNT FROM PAYMENT WHERE BOOKING_ID = ? AND PAYMENT_STATUS = 'SUCCESS') AS paid`,
    [req.params.id, req.params.id],
  );
  res.json(row);
});

// Lỗi từ SIGNAL / CHECK / FK trả nguyên thông báo của CSDL cho người dùng
app.use((err, req, res, next) => {
  if (err.sqlMessage) return res.status(400).json({ error: err.sqlMessage });
  console.error(err);
  res.status(500).json({ error: `Lỗi máy chủ: ${err.code || err.message}` });
});

const port = Number(process.env.PORT || 3000);
app.listen(port, () => console.log(`http://localhost:${port}`));
