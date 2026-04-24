# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_24_083947) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "dispatch_policy_adaptive_concurrency_stats", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "current_max", null: false
    t.float "ewma_latency_ms", default: 0.0, null: false
    t.string "gate_name", null: false
    t.datetime "last_observed_at"
    t.string "partition_key", default: "default", null: false
    t.string "policy_name", null: false
    t.integer "sample_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["policy_name", "gate_name", "partition_key"], name: "idx_dp_adaptive_concurrency_stats_unique", unique: true
  end

  create_table "dispatch_policy_partition_counts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "gate_name", null: false
    t.integer "in_flight", default: 0, null: false
    t.string "partition_key", default: "default", null: false
    t.string "policy_name", null: false
    t.datetime "updated_at", null: false
    t.index ["policy_name", "gate_name", "partition_key"], name: "idx_dp_partition_counts_unique", unique: true
  end

  create_table "dispatch_policy_partition_observations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "current_max"
    t.integer "max_lag_ms", default: 0, null: false
    t.datetime "minute_bucket", null: false
    t.integer "observation_count", default: 0, null: false
    t.string "partition_key", null: false
    t.string "policy_name", null: false
    t.bigint "total_lag_ms", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["minute_bucket"], name: "idx_dp_partition_observations_time"
    t.index ["policy_name", "partition_key", "minute_bucket"], name: "idx_dp_partition_observations_unique", unique: true
  end

  create_table "dispatch_policy_staged_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.datetime "admitted_at"
    t.jsonb "arguments", null: false
    t.datetime "completed_at"
    t.jsonb "context", default: {}, null: false
    t.datetime "created_at", null: false
    t.string "dedupe_key"
    t.string "job_class", null: false
    t.datetime "lease_expires_at"
    t.datetime "not_before_at"
    t.jsonb "partitions", default: {}, null: false
    t.string "policy_name", null: false
    t.integer "priority", default: 100, null: false
    t.string "round_robin_key"
    t.jsonb "snapshot", default: {}, null: false
    t.datetime "staged_at", null: false
    t.datetime "updated_at", null: false
    t.index ["completed_at"], name: "idx_dp_staged_completed_at", where: "(completed_at IS NOT NULL)"
    t.index ["lease_expires_at"], name: "idx_dp_staged_lease_expires", where: "(admitted_at IS NOT NULL)"
    t.index ["policy_name", "dedupe_key"], name: "idx_dp_staged_dedupe_active", unique: true, where: "((dedupe_key IS NOT NULL) AND (completed_at IS NULL))"
    t.index ["policy_name", "priority", "staged_at"], name: "idx_dp_staged_dispatch_order", where: "(admitted_at IS NULL)"
    t.index ["policy_name", "round_robin_key", "priority", "staged_at"], name: "idx_dp_staged_round_robin", where: "((admitted_at IS NULL) AND (round_robin_key IS NOT NULL))"
  end

  create_table "dispatch_policy_throttle_buckets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "gate_name", null: false
    t.string "partition_key", default: "default", null: false
    t.string "policy_name", null: false
    t.datetime "refilled_at", null: false
    t.float "tokens", null: false
    t.datetime "updated_at", null: false
    t.index ["policy_name", "gate_name", "partition_key"], name: "idx_dp_throttle_buckets_unique", unique: true
  end

  create_table "good_job_batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "callback_priority"
    t.text "callback_queue_name"
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "discarded_at"
    t.datetime "enqueued_at"
    t.datetime "finished_at"
    t.datetime "jobs_finished_at"
    t.text "on_discard"
    t.text "on_finish"
    t.text "on_success"
    t.jsonb "serialized_properties"
    t.datetime "updated_at", null: false
  end

  create_table "good_job_executions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "active_job_id", null: false
    t.datetime "created_at", null: false
    t.interval "duration"
    t.text "error"
    t.text "error_backtrace", array: true
    t.integer "error_event", limit: 2
    t.datetime "finished_at"
    t.text "job_class"
    t.uuid "process_id"
    t.text "queue_name"
    t.datetime "scheduled_at"
    t.jsonb "serialized_params"
    t.datetime "updated_at", null: false
    t.index ["active_job_id", "created_at"], name: "index_good_job_executions_on_active_job_id_and_created_at"
    t.index ["process_id", "created_at"], name: "index_good_job_executions_on_process_id_and_created_at"
  end

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "lock_type", limit: 2
    t.jsonb "state"
    t.datetime "updated_at", null: false
  end

  create_table "good_job_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "key"
    t.datetime "updated_at", null: false
    t.jsonb "value"
    t.index ["key"], name: "index_good_job_settings_on_key", unique: true
  end

  create_table "good_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "active_job_id"
    t.uuid "batch_callback_id"
    t.uuid "batch_id"
    t.text "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "cron_at"
    t.text "cron_key"
    t.text "error"
    t.integer "error_event", limit: 2
    t.integer "executions_count"
    t.datetime "finished_at"
    t.boolean "is_discrete"
    t.text "job_class"
    t.text "labels", array: true
    t.integer "lock_type", limit: 2
    t.datetime "locked_at"
    t.uuid "locked_by_id"
    t.datetime "performed_at"
    t.integer "priority"
    t.text "queue_name"
    t.uuid "retried_good_job_id"
    t.datetime "scheduled_at"
    t.jsonb "serialized_params"
    t.datetime "updated_at", null: false
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["batch_callback_id"], name: "index_good_jobs_on_batch_callback_id", where: "(batch_callback_id IS NOT NULL)"
    t.index ["batch_id"], name: "index_good_jobs_on_batch_id", where: "(batch_id IS NOT NULL)"
    t.index ["concurrency_key", "created_at"], name: "index_good_jobs_on_concurrency_key_and_created_at"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["created_at"], name: "index_good_jobs_on_created_at"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at_cond", where: "(cron_key IS NOT NULL)"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at_cond", unique: true, where: "(cron_key IS NOT NULL)"
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at_only", where: "(finished_at IS NOT NULL)"
    t.index ["finished_at"], name: "index_good_jobs_on_discarded", order: :desc, where: "((finished_at IS NOT NULL) AND (error IS NOT NULL))"
    t.index ["id"], name: "index_good_jobs_on_unfinished_or_errored", where: "((finished_at IS NULL) OR (error IS NOT NULL))"
    t.index ["job_class"], name: "index_good_jobs_on_job_class"
    t.index ["labels"], name: "index_good_jobs_on_labels", where: "(labels IS NOT NULL)", using: :gin
    t.index ["locked_by_id"], name: "index_good_jobs_on_locked_by_id", where: "(locked_by_id IS NOT NULL)"
    t.index ["priority", "created_at"], name: "index_good_job_jobs_for_candidate_lookup", where: "(finished_at IS NULL)"
    t.index ["priority", "created_at"], name: "index_good_jobs_jobs_on_priority_created_at_when_unfinished", order: { priority: "DESC NULLS LAST" }, where: "(finished_at IS NULL)"
    t.index ["priority", "scheduled_at", "id"], name: "index_good_jobs_for_candidate_dequeue_unlocked", where: "((finished_at IS NULL) AND (locked_by_id IS NULL))"
    t.index ["priority", "scheduled_at", "id"], name: "index_good_jobs_on_priority_scheduled_at_unfinished", where: "(finished_at IS NULL)"
    t.index ["priority", "scheduled_at"], name: "index_good_jobs_on_priority_scheduled_at_unfinished_unlocked", where: "((finished_at IS NULL) AND (locked_by_id IS NULL))"
    t.index ["queue_name", "scheduled_at", "id"], name: "index_good_jobs_on_queue_name_priority_scheduled_at_unfinished", where: "(finished_at IS NULL)"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_and_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["queue_name"], name: "index_good_jobs_on_queue_name"
    t.index ["scheduled_at", "queue_name"], name: "index_good_jobs_on_scheduled_at_and_queue_name"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
  end

  create_table "job_runs", force: :cascade do |t|
    t.string "account_id"
    t.datetime "created_at", null: false
    t.string "job_class"
    t.jsonb "payload"
    t.datetime "ran_at"
    t.datetime "updated_at", null: false
  end
end
