# Skill Index

Use this file to find the right skill for your task. Read the skill's `SKILL.md` or README before using it.

## Routing Protocol

Agents should trigger skills by task intent, not only when the user names a skill.

1. Classify the work: debugging, README, research audit, security, frontend, browser, MCP, documents, game, writing, memory, or architecture.
2. Search this index for matching `What` / `When` lines.
3. Read the selected skill's `SKILL.md`.
4. Follow the skill's workflow and use bundled scripts/references when relevant.
5. If no existing skill fits a complex task, search curated resources or public upstreams before inventing a workflow.

Public-safety note: this index is documentation, not a credential store. Do not add API keys, tokens, private paths with secrets, or account state.

## Obra-Superpowers

Core development workflows for systematic, high-quality work.

### systematic-debugging
- What: Root cause investigation before proposing fixes; prevents symptom-based patching
- When: Any bug, test failure, unexpected behavior, or performance problem
- Path: D:\agent-resources\skills\obra-superpowers\systematic-debugging

### test-driven-development
- What: Write tests first, then implementation; ensures correctness and prevents regressions
- When: Implementing any feature or bugfix before writing implementation code
- Path: D:\agent-resources\skills\obra-superpowers\test-driven-development

### dispatching-parallel-agents
- What: Coordinate multiple independent tasks across agents without shared state
- When: Facing 2+ independent tasks that can be worked on without sequential dependencies
- Path: D:\agent-resources\skills\obra-superpowers\dispatching-parallel-agents

### receiving-code-review
- What: Evaluate and implement code review feedback with technical rigor
- When: Receiving code review feedback, especially if unclear or technically questionable
- Path: D:\agent-resources\skills\obra-superpowers\receiving-code-review

### requesting-code-review
- What: Prepare work for peer review to verify requirements and quality
- When: Completing tasks, implementing major features, or before merging
- Path: D:\agent-resources\skills\obra-superpowers\requesting-code-review

### using-git-worktrees
- What: Create isolated workspaces for feature work using native git tools
- When: Starting feature work that needs isolation from current workspace
- Path: D:\agent-resources\skills\obra-superpowers\using-git-worktrees

### verification-before-completion
- What: Run verification commands and confirm output before claiming success
- When: About to claim work is complete, fixed, or passing before committing/PRs
- Path: D:\agent-resources\skills\obra-superpowers\verification-before-completion

### subagent-driven-development
- What: Delegate work to specialized sub-agents with clear specs and verification
- When: Complex tasks requiring multiple specialized agents or parallel work
- Path: D:\agent-resources\skills\obra-superpowers\subagent-driven-development

### writing-plans
- What: Create detailed execution plans before starting implementation
- When: Starting complex multi-step tasks or unfamiliar work
- Path: D:\agent-resources\skills\obra-superpowers\writing-plans

### executing-plans
- What: Follow execution plans systematically with progress tracking
- When: Working through complex multi-step tasks
- Path: D:\agent-resources\skills\obra-superpowers\executing-plans

## Anthropics

Anthropic-specific tools and integrations.

### claude-api
- What: Build, debug, and optimize Claude API / Anthropic SDK apps with prompt caching
- When: Code imports anthropic/@anthropic-ai/sdk; adding Claude features (caching, thinking, tool use, batch, files)
- Path: D:\agent-resources\skills\anthropics\claude-api

### mcp-builder
- What: Create high-quality MCP servers for LLM integration with external services
- When: Building MCP servers in Python (FastMCP) or Node/TypeScript (MCP SDK)
- Path: D:\agent-resources\skills\anthropics\mcp-builder

### webapp-testing
- What: Test local web applications using Playwright; verify UI, debug behavior, capture screenshots
- When: Testing frontend functionality or debugging UI behavior
- Path: D:\agent-resources\skills\anthropics\webapp-testing

### web-artifacts-builder
- What: Create complex claude.ai HTML artifacts with React, Tailwind CSS, shadcn/ui
- When: Building elaborate multi-component artifacts requiring state management or routing
- Path: D:\agent-resources\skills\anthropics\web-artifacts-builder

### skill-creator
- What: Create, modify, and optimize skills; run evals and benchmark performance
- When: Creating new skills, editing existing ones, or optimizing skill descriptions
- Path: D:\agent-resources\skills\anthropics\skill-creator

### doc-coauthoring
- What: Collaborate on document creation and editing
- When: Co-authoring documents with Claude
- Path: D:\agent-resources\skills\anthropics\doc-coauthoring

### pdf
- What: Extract, analyze, and manipulate PDF documents
- When: Working with PDF files programmatically
- Path: D:\agent-resources\skills\anthropics\pdf

### docx
- What: Create and manipulate Word documents
- When: Generating or editing .docx files
- Path: D:\agent-resources\skills\anthropics\docx

### xlsx
- What: Create and manipulate Excel spreadsheets
- When: Generating or editing .xlsx files
- Path: D:\agent-resources\skills\anthropics\xlsx

### pptx
- What: Create and manipulate PowerPoint presentations
- When: Generating or editing .pptx files
- Path: D:\agent-resources\skills\anthropics\pptx

### canvas-design
- What: Design visual layouts and graphics
- When: Creating visual designs or layouts
- Path: D:\agent-resources\skills\anthropics\canvas-design

### frontend-design
- What: Design and build frontend interfaces
- When: Creating frontend designs and implementations
- Path: D:\agent-resources\skills\anthropics\frontend-design

### brand-guidelines
- What: Apply and maintain brand consistency
- When: Ensuring brand compliance in designs
- Path: D:\agent-resources\skills\anthropics\brand-guidelines

### theme-factory
- What: Generate and manage design themes
- When: Creating or customizing design themes
- Path: D:\agent-resources\skills\anthropics\theme-factory

### slack-gif-creator
- What: Create animated GIFs for Slack
- When: Generating GIF content for Slack messages
- Path: D:\agent-resources\skills\anthropics\slack-gif-creator

### algorithmic-art
- What: Generate algorithmic art and visualizations
- When: Creating generative art or algorithmic visualizations
- Path: D:\agent-resources\skills\anthropics\algorithmic-art

## Context-Engineering-Kit

Systematic approaches to context, documentation, and development practices.

### tdd
- What: Test-driven development methodology
- When: Implementing features with test-first approach
- Path: D:\agent-resources\skills\context-engineering-kit\tdd

### ddd
- What: Domain-driven design principles
- When: Designing systems around business domains
- Path: D:\agent-resources\skills\context-engineering-kit\ddd

### sdd
- What: Specification-driven development
- When: Implementing from detailed specifications
- Path: D:\agent-resources\skills\context-engineering-kit\sdd

### sadd
- What: Specification-and-architecture-driven development
- When: Complex systems requiring both spec and architecture planning
- Path: D:\agent-resources\skills\context-engineering-kit\sadd

### review
- What: Code review practices and workflows
- When: Reviewing code or preparing for review
- Path: D:\agent-resources\skills\context-engineering-kit\review

### reflexion
- What: Reflection and learning from past work
- When: Analyzing past decisions and outcomes
- Path: D:\agent-resources\skills\context-engineering-kit\reflexion

### kaizen
- What: Continuous improvement methodology
- When: Incrementally improving processes or code
- Path: D:\agent-resources\skills\context-engineering-kit\kaizen

### git
- What: Git workflows and best practices
- When: Working with version control
- Path: D:\agent-resources\skills\context-engineering-kit\git

### mcp
- What: Model Context Protocol practices
- When: Working with MCP servers and tools
- Path: D:\agent-resources\skills\context-engineering-kit\mcp

### docs
- What: Documentation best practices
- When: Writing or maintaining documentation
- Path: D:\agent-resources\skills\context-engineering-kit\docs

### fpf
- What: Fail-fast, fail-forward principles
- When: Rapid iteration and learning
- Path: D:\agent-resources\skills\context-engineering-kit\fpf

### tech-stack
- What: Technology stack selection and management
- When: Choosing or evaluating tech stacks
- Path: D:\agent-resources\skills\context-engineering-kit\tech-stack

### customaize-agent
- What: Customize agent behavior and capabilities
- When: Configuring agents for specific tasks
- Path: D:\agent-resources\skills\context-engineering-kit\customaize-agent

## Vipin

Specialized skills for Lark, communication, and content creation.

### lark-cli
- What: Command-line interface for Lark platform operations
- When: Automating Lark operations via CLI
- Path: D:\agent-resources\skills\vipin\lark-cli

### lark-base
- What: Lark Base (database) operations and automation
- When: Working with Lark Base databases
- Path: D:\agent-resources\skills\vipin\lark-base

### lark-doc
- What: Lark Doc (document) creation and management
- When: Creating or managing Lark documents
- Path: D:\agent-resources\skills\vipin\lark-doc

### lark-sheets
- What: Lark Sheets (spreadsheet) operations
- When: Working with Lark spreadsheets
- Path: D:\agent-resources\skills\vipin\lark-sheets

### lark-drive
- What: Lark Drive (file storage) operations
- When: Managing files in Lark Drive
- Path: D:\agent-resources\skills\vipin\lark-drive

### lark-calendar
- What: Lark Calendar operations and scheduling
- When: Managing calendar events in Lark
- Path: D:\agent-resources\skills\vipin\lark-calendar

### lark-contact
- What: Lark Contact management
- When: Managing contacts in Lark
- Path: D:\agent-resources\skills\vipin\lark-contact

### lark-im
- What: Lark Instant Messaging operations
- When: Sending messages via Lark
- Path: D:\agent-resources\skills\vipin\lark-im

### lark-wiki
- What: Lark Wiki (knowledge base) operations
- When: Creating or managing Lark Wiki content
- Path: D:\agent-resources\skills\vipin\lark-wiki

### lark-slides
- What: Lark Slides (presentation) creation
- When: Creating presentations in Lark
- Path: D:\agent-resources\skills\vipin\lark-slides

### lark-markdown
- What: Lark Markdown formatting and conversion
- When: Working with Markdown in Lark
- Path: D:\agent-resources\skills\vipin\lark-markdown

### lark-openapi-explorer
- What: Explore and test Lark OpenAPI
- When: Testing Lark API endpoints
- Path: D:\agent-resources\skills\vipin\lark-openapi-explorer

### lark-shared
- What: Shared Lark utilities and helpers
- When: Using common Lark functionality
- Path: D:\agent-resources\skills\vipin\lark-shared

### lark-skill-maker
- What: Create custom Lark skills
- When: Building new Lark integrations
- Path: D:\agent-resources\skills\vipin\lark-skill-maker

### feishu-bridge
- What: Bridge between Feishu and other systems
- When: Integrating Feishu with external services
- Path: D:\agent-resources\skills\vipin\feishu-bridge

### communication-assistant
- What: Assist with communication tasks
- When: Drafting or managing communications
- Path: D:\agent-resources\skills\vipin\communication-assistant

### email-assistant
- What: Email management and automation
- When: Handling email tasks
- Path: D:\agent-resources\skills\vipin\email-assistant

### content-creation-publisher
- What: Create and publish content
- When: Publishing content to multiple platforms
- Path: D:\agent-resources\skills\vipin\content-creation-publisher

### chrome-automation
- What: Automate Chrome browser tasks
- When: Automating browser interactions
- Path: D:\agent-resources\skills\vipin\chrome-automation

### frontend-design
- What: Frontend design and implementation
- When: Creating frontend designs
- Path: D:\agent-resources\skills\vipin\frontend-design

### readme-blueprint-generator
- What: Generate README files from templates
- When: Creating project documentation
- Path: D:\agent-resources\skills\vipin\readme-blueprint-generator

### wechat-video-channel-publish
- What: Publish videos to WeChat channels
- When: Publishing video content to WeChat
- Path: D:\agent-resources\skills\vipin\wechat-video-channel-publish

### paper-orchestra
- What: Orchestrate academic paper workflows
- When: Managing academic paper projects
- Path: D:\agent-resources\skills\vipin\paper-orchestra

## Trail of Bits

Security and testing expertise.

### agentic-actions-auditor
- What: Audit agent actions for security and correctness
- When: Reviewing agent behavior and decisions
- Path: D:\agent-resources\skills\trailofbits\agentic-actions-auditor

### ask-questions-if-underspecified
- What: Identify and clarify underspecified requirements
- When: Requirements are vague or incomplete
- Path: D:\agent-resources\skills\trailofbits\ask-questions-if-underspecified

### audit-context-building
- What: Audit how context is built and used
- When: Reviewing context management
- Path: D:\agent-resources\skills\trailofbits\audit-context-building

### building-secure-contracts
- What: Design and implement secure smart contracts
- When: Building blockchain contracts
- Path: D:\agent-resources\skills\trailofbits\building-secure-contracts

### static-analysis
- What: Perform static code analysis
- When: Analyzing code for issues without execution
- Path: D:\agent-resources\skills\trailofbits\static-analysis

### mutation-testing
- What: Test code quality via mutation testing
- When: Evaluating test suite effectiveness
- Path: D:\agent-resources\skills\trailofbits\mutation-testing

### property-based-testing
- What: Generate test cases via property-based testing
- When: Testing with generated inputs
- Path: D:\agent-resources\skills\trailofbits\property-based-testing

### semgrep-rule-creator
- What: Create Semgrep rules for code analysis
- When: Building custom static analysis rules
- Path: D:\agent-resources\skills\trailofbits\semgrep-rule-creator

### variant-analysis
- What: Analyze code variants for consistency
- When: Comparing similar code implementations
- Path: D:\agent-resources\skills\trailofbits\variant-analysis

### supply-chain-risk-auditor
- What: Audit supply chain security risks
- When: Evaluating dependency and integration risks
- Path: D:\agent-resources\skills\trailofbits\supply-chain-risk-auditor

### constant-time-analysis
- What: Analyze code for timing vulnerabilities
- When: Reviewing cryptographic or security-sensitive code
- Path: D:\agent-resources\skills\trailofbits\constant-time-analysis

### differential-review
- What: Review code changes systematically
- When: Reviewing pull requests or diffs
- Path: D:\agent-resources\skills\trailofbits\differential-review

### spec-to-code-compliance
- What: Verify code matches specifications
- When: Ensuring implementation matches spec
- Path: D:\agent-resources\skills\trailofbits\spec-to-code-compliance

## Standalone

Specialized single-purpose skills.

### gsap-core
- What: GSAP animation library core concepts
- When: Working with GSAP animations
- Path: D:\agent-resources\skills\standalone\gsap-core

### gsap-react
- What: GSAP integration with React
- When: Using GSAP in React projects
- Path: D:\agent-resources\skills\standalone\gsap-react

### gsap-scrolltrigger
- What: GSAP ScrollTrigger plugin for scroll animations
- When: Creating scroll-based animations
- Path: D:\agent-resources\skills\standalone\gsap-scrolltrigger

### gsap-timeline
- What: GSAP Timeline for complex animations
- When: Orchestrating multiple animations
- Path: D:\agent-resources\skills\standalone\gsap-timeline

### gsap-plugins
- What: GSAP plugin ecosystem
- When: Using advanced GSAP plugins
- Path: D:\agent-resources\skills\standalone\gsap-plugins

### gsap-performance
- What: Optimize GSAP animation performance
- When: Improving animation performance
- Path: D:\agent-resources\skills\standalone\gsap-performance

### gsap-frameworks
- What: GSAP integration with frameworks
- When: Using GSAP with Vue, Angular, etc.
- Path: D:\agent-resources\skills\standalone\gsap-frameworks

### gsap-utils
- What: GSAP utility functions and helpers
- When: Using GSAP utilities
- Path: D:\agent-resources\skills\standalone\gsap-utils

### darwin-skill
- What: Darwin evolutionary algorithm implementation
- When: Implementing genetic algorithms
- Path: D:\agent-resources\skills\standalone\darwin-skill

### nuwa-skill
- What: MIT-licensed person/mentor skill distillation workflow ("女娲造人"): deep research -> thinking-frame extraction -> runnable perspective skill.
- When: The user wants to create, update, or choose a person/topic perspective skill from an explicit name or a vague thinking/decision need.
- Path: D:\agent-resources\skills\standalone\nuwa-skill

### colleague-skill
- What: Colleague agent collaboration
- When: Working with colleague agents
- Path: D:\agent-resources\skills\standalone\colleague-skill

### anbeime-skill
- What: Anbeime platform integration
- When: Working with Anbeime
- Path: D:\agent-resources\skills\standalone\anbeime-skill

### deepseek-mcp
- What: DeepSeek MCP server integration
- When: Using DeepSeek models via MCP
- Path: D:\agent-resources\skills\standalone\deepseek-mcp

### mattpocock-skills
- What: Matt Pocock's TypeScript and web development skills
- When: Advanced TypeScript or web development patterns
- Path: D:\agent-resources\skills\standalone\mattpocock-skills

### canon-pianist-ai-video-project
- What: AI video generation for piano performances
- When: Creating AI-generated piano videos
- Path: D:\agent-resources\skills\standalone\canon-pianist-ai-video-project

## Composio

Composio automation integrations (1000+ services).

Composio provides automation skills for integrating with external services. Key categories include:

- **Communication**: Slack, Discord, Telegram, WhatsApp, Email services
- **Project Management**: Jira, Asana, Monday.com, Trello, Linear
- **CRM**: Salesforce, HubSpot, Pipedrive, Zoho
- **Finance**: Stripe, PayPal, QuickBooks, Xero
- **Cloud**: AWS, Google Cloud, Azure, DigitalOcean
- **Data**: Airtable, Notion, Google Sheets, Zapier
- **AI/ML**: OpenAI, Anthropic, Hugging Face, Replicate
- **Web**: Shopify, WordPress, Webflow, Wix
- **Analytics**: Google Analytics, Mixpanel, Amplitude
- **And 900+ more services**

Path: D:\agent-resources\skills\composio\{service-name}-automation

## Graphify

Graph visualization and analysis.

### graphify
- What: Create and analyze graph visualizations
- When: Visualizing network or hierarchical data
- Path: D:\agent-resources\skills\graphify\graphify

## MCP Tools (configured in ~/.claude/mcp.json)

These are always-available MCP servers, not file-based skills. Any agent sharing the CC MCP config can use them directly.

### media-gen
- What: Generate images via gpt-image-2 (OpenAI), saves to local disk
- When: Need to create illustrations, diagrams, banners, paper figures, any image generation task
- How: MCP tool call (auto-available in CC/ARIS sessions), uses 9100 rotator

### agentmemory
- What: Persistent shared memory — search, recall, lessons, signals, actions
- When: Always (session start search, cross-agent communication, saving lessons)
- How: MCP tool calls (memory_smart_search, memory_recall, memory_save, etc.)

### codex (reviewer)
- What: Invoke Codex/GPT-5.5 as an external reviewer
- When: Research review, code audit, getting a second opinion from a different model
- How: MCP tool call, used by ARIS /research-review and /auto-review-loop skills

---

## ECC — Agent Harness Performance System

232 skills + 60 agents for Claude Code, Codex, Cursor, OpenCode, Gemini, and more. The most comprehensive open-source agent harness available.

**Install (plugin, recommended):**
```
/plugin marketplace add https://github.com/affaan-m/ECC
/plugin install ecc@ecc
```

**Key commands:** `/ecc:plan`, `/code-review`, `/security-scan`, `/build-fix`, `/refactor-clean`, `/test-coverage`, `/instinct-status`, `/evolve`, `/harness-audit`

**Components at** `D:\agent-resources\skills\ecc\`:
- `skills/` — 232 workflow skills (TDD, security, frontend, backend, ML, agent-harness, etc.)
- `agents/` — 60 specialized subagents (architect, code-reviewer, security-reviewer, tdd-guide, planner, etc.)
- `rules/` — always-on coding guidelines (common + language-specific: TS, Python, Go, Swift, PHP)
- `hooks/` — event-driven automations (tool use, session start/stop, file edits)
- `mcp-configs/` — MCP server definitions (GitHub, Supabase, Vercel, etc.)
- `COMMANDS-QUICK-REF.md` — full command reference
- `the-shortform-guide.md` — quick-start guide

**Notable features:**
- AgentShield: 102-rule security scanner for CLAUDE.md, hooks, MCP configs
- Continuous Learning v2: instinct extraction with confidence scoring
- Dashboard GUI: `python3 ecc_dashboard.py` or `npm run dashboard`
- Hook tuning via env vars: `ECC_HOOK_PROFILE=minimal|standard|strict`

Path: D:\agent-resources\skills\ecc\

---

## Karpathy Guidelines

Behavioral guidelines derived from Andrej Karpathy's observations on LLM coding pitfalls.

### karpathy-guidelines
- What: Four coding principles — Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven Execution
- When: Writing, reviewing, or refactoring any code to avoid overcomplication and scope creep
- Path: D:\agent-resources\skills\standalone\karpathy-guidelines

---

## Understand-Anything

Turn any codebase or knowledge base into an interactive knowledge graph.

### understand
- What: Build a knowledge graph from a codebase using Tree-sitter + LLM semantic analysis
- When: Starting work on an unfamiliar codebase; need architecture overview
- Path: D:\agent-resources\skills\standalone\understand

### understand-chat
- What: Ask natural language questions about the codebase knowledge graph
- When: Exploring how components relate, tracing data flows, answering "where is X"
- Path: D:\agent-resources\skills\standalone\understand-chat

### understand-dashboard
- What: Open the interactive visual knowledge graph explorer
- When: Need a visual map of the codebase structure
- Path: D:\agent-resources\skills\standalone\understand-dashboard

### understand-diff
- What: Analyze the impact of current changes on the codebase graph
- When: Before committing; want to know what a change touches
- Path: D:\agent-resources\skills\standalone\understand-diff

### understand-explain
- What: Deep-dive explanation of a specific file or function
- When: Need to understand a complex module in detail
- Path: D:\agent-resources\skills\standalone\understand-explain

### understand-onboard
- What: Generate an onboarding guide for new team members
- When: Onboarding someone to a codebase; writing contributor docs
- Path: D:\agent-resources\skills\standalone\understand-onboard

### understand-domain
- What: Extract business domain knowledge (domains, flows, steps) from code
- When: Need to understand business logic embedded in the codebase
- Path: D:\agent-resources\skills\standalone\understand-domain

### understand-knowledge
- What: Analyze a Karpathy-pattern LLM wiki into a knowledge graph
- When: Working with a wiki-style knowledge base (markdown files)
- Path: D:\agent-resources\skills\standalone\understand-knowledge

---

## Presentation as Code

Create high-impact, interactive HTML presentations through AI collaboration.

### presentation-as-code
- What: Build standalone HTML slide decks with shared design system, data viz, offline-first
- When: Creating training materials, pitch decks, tech talks, or any visual storytelling
- Path: D:\agent-resources\skills\standalone\presentation-as-code

---

## CodeGraph (MCP Tool)

Pre-indexed code knowledge graph for AI agents — fewer tokens, fewer tool calls, 100% local.

### codegraph-add-lang
- What: Add a new language to CodeGraph's tree-sitter parser
- When: Working with a language not yet supported by CodeGraph
- Path: D:\agent-resources\skills\standalone\codegraph-add-lang

### codegraph-agent-eval
- What: Evaluate agent performance against CodeGraph benchmarks
- When: Benchmarking or comparing agent behavior on codebase queries
- Path: D:\agent-resources\skills\standalone\codegraph-agent-eval

---

## Claude Plugins Official (Anthropic)

Official Anthropic-managed plugins for Claude Code workflows.

### code-review (plugin)
- What: Automated PR code review using multiple specialized agents with confidence scoring
- When: Reviewing pull requests; want multi-agent review with structured output
- Path: D:\agent-resources\skills\claude-plugins-official\code-review

### feature-dev (plugin)
- What: End-to-end feature development workflow with agents and commands
- When: Implementing a new feature from spec to code
- Path: D:\agent-resources\skills\claude-plugins-official\feature-dev

### code-modernization (plugin)
- What: Modernize legacy code to current language/framework standards
- When: Upgrading old codebases, migrating deprecated APIs
- Path: D:\agent-resources\skills\claude-plugins-official\code-modernization

### pr-review-toolkit (plugin)
- What: Comprehensive PR review toolkit with agents and commands
- When: Thorough pull request review with structured checklist
- Path: D:\agent-resources\skills\claude-plugins-official\pr-review-toolkit

### agent-sdk-dev (plugin)
- What: Build agents using the Claude Agent SDK
- When: Creating custom agents with the Anthropic Agent SDK
- Path: D:\agent-resources\skills\claude-plugins-official\agent-sdk-dev

### security-guidance (plugin)
- What: Security review and guidance for code changes
- When: Security-sensitive code; want automated security analysis
- Path: D:\agent-resources\skills\claude-plugins-official\security-guidance

### code-simplifier (plugin)
- What: Simplify and reduce complexity in existing code
- When: Code is too complex, over-engineered, or hard to read
- Path: D:\agent-resources\skills\claude-plugins-official\code-simplifier

### commit-commands (plugin)
- What: Structured git commit workflow with conventional commits
- When: Creating commits with consistent format and quality
- Path: D:\agent-resources\skills\claude-plugins-official\commit-commands

### claude-code-setup (plugin)
- What: Set up Claude Code for a new project (CLAUDE.md, settings, hooks)
- When: Initializing Claude Code in a new repo
- Path: D:\agent-resources\skills\claude-plugins-official\claude-code-setup

### claude-md-management (plugin)
- What: Manage and maintain CLAUDE.md files across a project
- When: Keeping CLAUDE.md up to date as the project evolves
- Path: D:\agent-resources\skills\claude-plugins-official\claude-md-management

### mcp-tunnels (plugin)
- What: Set up MCP tunnels for remote/cloud MCP server access
- When: Connecting to MCP servers over network tunnels
- Path: D:\agent-resources\skills\claude-plugins-official\mcp-tunnels

### hookify (plugin)
- What: Create and manage Claude Code hooks with writing-rules skill
- When: Setting up automated hooks for Claude Code events
- Path: D:\agent-resources\skills\claude-plugins-official\hookify

### session-report (plugin)
- What: Generate structured session reports summarizing work done
- When: End of a work session; want a summary of changes and decisions
- Path: D:\agent-resources\skills\claude-plugins-official\session-report

### build-mcp-server (skill)
- What: Build a production-ready MCP server from scratch
- When: Creating a new MCP server (more detailed than mcp-builder)
- Path: D:\agent-resources\skills\standalone\build-mcp-server

### build-mcp-app (skill)
- What: Build an application that consumes MCP servers
- When: Creating a client app that uses MCP tools
- Path: D:\agent-resources\skills\standalone\build-mcp-app

### session-report (skill)
- What: Generate a structured end-of-session report
- When: Wrapping up a work session; want a summary for handoff
- Path: D:\agent-resources\skills\standalone\session-report

### hookify-writing-rules (skill)
- What: Rules for writing effective Claude Code hooks
- When: Creating hooks; want best practices for hook scripts
- Path: D:\agent-resources\skills\standalone\hookify-writing-rules

---

## Academic Research Skills

Comprehensive Claude Code skill suite for the full academic research pipeline — from ideation to publication.

### ars-plan
- What: Socratic dialogue to walk through paper structure and research plan
- When: Starting a new paper; need to clarify research question, method, and contribution
- Path: D:\agent-resources\repos\academic-research-skills\academic-pipeline

### ars-write
- What: Human-in-the-loop writing assistance with style calibration and quality checks
- When: Drafting or revising paper sections; want AI to match your voice, not replace it
- Path: D:\agent-resources\repos\academic-research-skills\academic-paper

### ars-review
- What: Automated paper review with integrity gates (hallucination, citation, logic checks)
- When: Pre-submission review; want a structured checklist before submitting
- Path: D:\agent-resources\repos\academic-research-skills\academic-paper-reviewer

### ars-deep-research
- What: Deep literature search and synthesis with trust-chain citation provenance
- When: Literature review; need to find, verify, and synthesize related work
- Path: D:\agent-resources\repos\academic-research-skills\deep-research

---

## AI Engineering from Scratch

435-lesson, 20-phase open curriculum for building AI systems end-to-end (Python, TypeScript, Rust, Julia). Every lesson ships a reusable artifact.

### ai-engineering-curriculum
- What: Structured curriculum from ML fundamentals to production agents and MCP servers
- When: Learning AI engineering systematically; building reference implementations
- Path: D:\agent-resources\repos\ai-engineering-from-scratch\phases

### ai-engineering-projects
- What: Hands-on project templates for each curriculum phase
- When: Need a starter project for a specific AI engineering topic
- Path: D:\agent-resources\repos\ai-engineering-from-scratch\projects

---

## OpenHuman

Open-source personal AI super-intelligence harness — local memory, managed services, human-in-the-loop design.

### openhuman
- What: Personal AI assistant with local memory, tool integrations, and human-centered UX
- When: Building or extending a personal AI assistant; need a reference harness architecture
- Path: D:\agent-resources\repos\openhuman

---

## Game Development

Complete game development pipeline — from brainstorming to release.

### Claude-Code-Game-Studios (73 skills, 49 agents)
- What: Full game studio hierarchy — directors, leads, specialists for Godot/Unity/UE5
- When: Building any game; need structured workflow (brainstorm → design → architecture → sprint → QA → release)
- Key skills: /start, /brainstorm, /create-architecture, /sprint-plan, /prototype, /vertical-slice, /playtest-report, /release-checklist
- Path: D:\agent-resources\skills\game-studios\
- Public status: local-only pending provenance/license clearance; do not route implicitly from the public index until cleared.

### Godogen (autonomous game generation)
- What: Autonomous game generation pipeline with screenshot-based self-repair
- When: Want AI to generate a complete game from a description (Godot 4 / Bevy / Babylon.js)
- Key feature: Frame-grounded self-repair — judges progress from screenshots, not just compilation
- Path: D:\agent-resources\skills\godogen\
- Public status: local-only pending provenance/license clearance; do not route implicitly from the public index until cleared.

### GSD-2 (spec-driven development, 58.9k stars)
- What: Meta-prompting system that prevents context rot; breaks work into atomic plans
- When: Any complex project where "just prompting" produces bad results; need spec → plan → task → implement flow
- Note: Full runtime (not just skills) — reference for methodology. Use its workflow pattern.
- Path: D:\agent-resources\repos\gsd-2\

---

## InkOS

Autonomous novel writing AI agent with multi-agent pipeline and web workbench.

### inkos
- What: Autonomous fiction writing — multi-agent pipeline (Radar→Planner→Composer→Architect→Writer→Observer→Reflector→Normalizer→Auditor→Reviser), 33-dimension auditing, style imitation, fan fiction, AIGC detection, EPUB export, InkOS Studio web UI
- When: Creative fiction writing, novel generation, short fiction packages, cover generation, chapter continuation/import, style analysis
- Path: D:\agent-resources\skills\inkos

---

## Quick Reference

**For comprehensive harness**: ECC (232 skills + 60 agents at skills/ecc/)
**For game development**: GSD-2 (spec-driven). The local game-studios and godogen packs are useful for inspection but are not public-routed until provenance/license clearance is complete.
**For debugging**: systematic-debugging
**For features**: test-driven-development or feature-dev (plugin)
**For parallel work**: dispatching-parallel-agents
**For code review**: requesting-code-review, receiving-code-review, or code-review (plugin)
**For Claude API**: claude-api
**For MCP servers**: mcp-builder, build-mcp-server, or build-mcp-app
**For testing web apps**: webapp-testing
**For complex artifacts**: web-artifacts-builder
**For Lark integration**: lark-* skills
**For security review**: Trail of Bits skills or security-guidance (plugin)
**For external services**: Composio skills
**For presentations**: presentation-as-code
**For codebase understanding**: understand-* skills or codegraph
**For coding discipline**: karpathy-guidelines
**For session wrap-up**: session-report
**For hooks**: hookify or hookify-writing-rules
**For academic research**: academic-research-skills
**For AI engineering curriculum**: ai-engineering-from-scratch
**For personal AI assistant**: openhuman
