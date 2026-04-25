-- --------------------------------------------------
-- 題目三：找出分數排名第二名學生所在的班級
--
-- Database: student
-- Table: score (name, score) / class (name, class)
--
-- 思路：
--   1. 從 score 表取分數第二高的學生
--      用 ORDER BY score DESC + LIMIT 1 OFFSET 1 跳過第一名取第二名
--   2. JOIN class 表，透過 name 關聯取得該學生的班級
--
-- 預期結果：John 的分數 97 為第二名，班級為 A
-- --------------------------------------------------

SELECT c.class
FROM score s
JOIN class c ON s.name = c.name
ORDER BY s.score DESC
LIMIT 1 OFFSET 1;
