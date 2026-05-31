# S1 Sovereign Codex — 01. コア哲学と絶対ルール

> **Phase 597 / 2026-05-21 — S1 Sovereign Factory が全プロジェクトを統治する**

## S1 Sovereign Factory とは

S1 Sovereign Factory は、複数のAIプロジェクトを統合管理する**最上位プラットフォーム**である。
配下に以下のサブプロジェクトを持つ:

- **A3 Antigravity Racing** — 競馬予測・IPAT自動購入パイプライン
- **H1 Chrono Map Kamakura** — 鎌倉歴史マップ（A3とは完全独立）

S1は単なるプロジェクト管理ツールではなく、**自律型エージェント開発基盤**として機能する。
タスクキュー、ガバナンスエンジン、ReActループ、エピソード記憶、プロンプト進化を全てDB-Firstで実装し、
サブエージェントが自律的にコードを書き、テストし、デプロイする世界を目指す。

---

## S1 コア憲法 (14条)

いかなる開発フェーズ・指示においても、以下のルールは全プロジェクト共通の**絶対的な前提**として機能する。

### 第1条: データの正当性至上主義
データが正しくなければシステムは砂上の楼閣。即座に入力から洗い直し。

### 第2条: コンテキスト肥大化の防止
コンテキストが増大したら即刻タスクを小分けし、引き継ぎ書と申し送り事項をまとめる。

### 第3条: 絶対的な DB ファースト (Fat DB / Thin Python)
徹底したDBファースト。ロジックはSQL/PLpgSQLで実装する。Pythonは薄いラッパーのみ。
推論チェーン全体がdbt DAG管理下。設定・メタデータ・ガバナンスルール全てがDBに格納される。

### 第4条: プロセス不沈 (No-Kill) の原則
`sys.exit()` の使用は厳禁。エラーをキャッチして自動復旧する。OOM Killerからも復帰する設計。

### 第5条: 先祖返りとアーキテクチャ破壊の絶対防止
トポロジー的・ファジィな重複スライスの単純化は「システムの破壊行為」。
設計書とメタ学習の更新を義務付け、知識の退行を物理的に防止する。

### 第6条: 直交特徴の探求と外部知見の吸収
TakeTube（YouTube AI）、VictGrab（外部AIスコア）、Heritage DNA、H1歴史知識など、
主データソースと直交する情報源を積極的に統合する。

### 第7条: 外部ツールの徹底管理と活用
ローカルLLM、無料LLM枠、APIキー等の外部リソースはDBで一元管理する。
シークレットは `a3_meta.system_secrets` に格納。

### 第8条: 一貫テストとログの精査
機能修正後にテストを行い、矛盾があれば修正。dbt test全PASSを維持する。
ダミーテストは禁止。本番データでの検証を必須とする。

### 第9条: JRA-VAN直接連携
JV-Link COMからS1配下A3のPythonパイプラインで直接取り込むアーキテクチャのみを正とする。

### 第10条: 使い捨てスクリプトの厳禁
test_*.py, debug_*.py等の使い捨てスクリプト作成・放置は厳禁。
`scratch/` への放置はセッション末までに削除 or 統合。

### 第11条: ガードレール自己保護（メタ防御）
ガバナンスチェック項目の削除・無効化は「システム破壊行為」。
サーキットブレーカー、DLQ Auto-Medic等の防御機構は不可侵。

### 第12条: データ資産の不可侵
tyb_parsed, sed_parsed, chrono_archive.*, 学習用MATVIEW, 多層学習構造の削除禁止。

### 第13条: True L3 アーキテクチャの死守
50層・独立馬券種(6モデル)・トポロジー適応を絶対に単一スコアに集約しない。

### 第14条: H1 完全分離 (Core Rule #14)
H1 Chrono Map Kamakura はA3とは完全に独立したサブプロジェクト。
A3のdbtモデル・テスト・パイプラインにH1のコードを混入させない。
ただしS1の統合ダッシュボードからは横断的に監視する。

---

## S1 タスクキュー移譲義務（S1サブエージェント・ファースト原則）

Phase 596で制定。旧Bucket Relay移譲義務を発展的に継承。

1. SQL_EXEC/AUDIT/HEALTH_CHECK等で自動化できるものは全てタスクキューに投入
2. 軽微なコード修正は **S1サブエージェント（s1_queue_worker）に委譲**
3. タスクキューの機能で対応できない作業がある場合、S1サブエージェント自体の強化を優先
4. サブエージェント方式:
   - `s1_embedded` — 単発ルール埋込型
   - `s1_queue_worker` — キュー消化型（BR代替本体）
   - `s1_architect` — 並列タスク分解型

---

## セッション開始プロトコル

```bash
# Step 1: セッション登録 + 整合性チェック + ガバナンス起動
docker exec a3-postgres-15 psql -U postgres -d pckeiba \
  -c "SELECT * FROM a3_meta.session_start(N, 'AgentName');" \
  -c "SELECT * FROM a3_meta.check_handover_integrity(N);" \
  -c "SELECT * FROM a3_meta.governance_kickstart(N, 'AgentName');"
# Step 2: ガバナンスpreflight実行
docker exec a3-sovereign-worker python -X utf8 /app/a3_governance.py --preflight
# Step 3: dbt run/test で全PASS確認
```

check_handover_integrity で CRITICAL が出たら、前セッションの不備を修正してから本作業開始。

---

## Python 正当性チェック (Phase 493制定)

全 `/app/*.py` に `# A3_PYTHON_JUSTIFICATION: [CATEGORY] reason` タグが必須。

| カテゴリ | 説明 | dbt移管 |
|---|---|---|
| INFRA | システム基盤 (デーモン、DB接続) | ❌ |
| ML_RUNTIME | CatBoost推論・LLM連携 | ❌ |
| BROWSER | Playwright/IPAT自動投票 | ❌ |
| JRAVAN | JV-Link COM/JRDB固定長パース | ❌ |
| TAKETUBE | YouTube字幕取得・LLM解析 | ❌ |
| RACEDAY | レースデースケジューラ | ❌ |
| UTILITY | 一時スクリプト | ✅ 即dbt/SQLへ移管 |

*Phase 597 / S1 Sovereign Codex v1.0*


### Phase 6 Architectural Updates (Cross-Reference)
- **DB IDs**: Primary keys are now `UUID` via `gen_random_uuid()`.
- **Read/Write Schemas**: Reader systems read from the `api` schema, NOT `chrono_archive` or `public`.
- **dbt Models**: A3 uses `materialized='incremental'` with `updated_at` checks.
- **Governance**: Autonomous "Integration Sentinels" deep-audit code vs markdown designs.
- **Orchestrator**: Bucket-brigade "Orchestrator" pattern spawns Healer/Sentinel subagents.
- **Error Handling**: 503 Capacity errors and Mojibake bugs are self-healed by Sentinels.
