--table list device
CREATE TABLE IF NOT EXISTS tb_list_device(id_device TEXT NOT NULL PRIMARY KEY,address VARCHAR(100) UNIQUE NOT NULL,nama VARCHAR(100) NOT NULL,jenis VARCHAR(100) NOT NULL,setatus VARCHAR(10) NOT NULL,lokasi VARCHAR(100),keterangan VARCHAR(100),created_at TIMESTAMP,updated_at TIMESTAMP)

--table power_meter
CREATE TABLE IF NOT EXISTS tb_logpower(time TIMESTAMPTZ NOT NULL,id_device TEXT NOT NULL,volt DECIMAL(18,2), ampere DECIMAL(18,2), watt DECIMAL(18,2), kwh DECIMAL(18,3), freq DECIMAL(18,2), pf DECIMAL(18,2))

--create hyper table
SELECT create_hypertable('tb_logpower','time');

--create index table
CREATE INDEX pow_id_time ON tb_logpower (id_device, time DESC);

--create continouos aggregate for daily view
CREATE MATERIALIZED VIEW power_daily WITH (timescaledb.continuous) AS SELECT time_bucket('1 day', "time") AS day, id_device, max(volt) AS v_high, min(volt) AS v_low, avg(volt) AS v_avg, max(ampere) AS a_high, min(ampere) AS a_low, avg(ampere) AS a_avg, max(watt) AS w_high, min(watt) AS w_low, avg(watt) AS w_avg, min(kwh) as kwh_min, max(kwh) as kwh_max FROM tb_logpower GROUP BY day, id_device;

--create refresh policy
SELECT add_continuous_aggregate_policy('power_daily', start_offset => INTERVAL '3 days',end_offset => INTERVAL '1 hour', schedule_interval => INTERVAL '1 days');

--create kwh_day_by_day
create materialized view kwh_day_by_day(time, value)
   with (timescaledb.continuous) as
SELECT time_bucket('1 day', created, 'Asia/Jakarta') AS "time",
      round((last(value, created) - first(value, created)) * 100.) / 100. AS value
FROM tb_logpower
GROUP BY 1
ORDER BY 1;

--create refresh policy for kwh_day_by_day
SELECT add_continuous_aggregate_policy('kwh_day_by_day', start_offset => INTERVAL '3 days',end_offset => INTERVAL '1 hour', schedule_interval => INTERVAL '1 days');

--create kwh_hour_by_hour
create materialized view kwh_day_by_day(time, value)
   with (timescaledb.continuous) as
SELECT time_bucket('01:00:00', created, 'Asia/Jakarta') AS "time",
      round((last(value, created) - first(value, created)) * 100.) / 100. AS value
FROM tb_logpower
GROUP BY 1
ORDER BY 1;

--create refresh policy for kwh_hour_by_hour

SELECT add_continuous_aggregate_policy('kwh_hour_by_hour', start_offset => INTERVAL '3 days',end_offset => INTERVAL '1 hour', schedule_interval => INTERVAL '1 hour');

--create retention policy
SELECT add_retention_policy('tb_logpower', INTERVAL '6 month');
