# AI Knowledge Base

Thư mục này chứa cơ sở kiến thức chung và riêng biệt mà các công cụ AI (Devin, Cursor, Cline) tham chiếu đến.

## Cấu trúc thư mục

```
.ai-knowledge/
├── common/                  # Thông tin dùng chung cho tất cả công cụ AI
│   ├── repo-specific/       # Thông tin dùng chung nhưng riêng cho từng repository
│   │   ├── 01_project-overview.md  # Tổng quan dự án
│   │   ├── 02_architecture.md      # Thông tin kiến trúc
│   │   ├── 03_deployment.md        # Thông tin liên quan đến triển khai
│   │   └── 04_conventions.md       # Quy ước lập trình, chiến lược Git, v.v.
│   └── repo-shared.md       # Tham chiếu đến kiến thức chung giữa các repository
├── devin/                   # Thông tin riêng của Devin
│   └── specific.md
├── cursor/                  # Thông tin riêng của Cursor
│   └── specific.md
└── cline/                   # Thông tin riêng của Cline
    └── specific.md

```

## Cách sử dụng

Mỗi công cụ AI sẽ tham chiếu đến thông tin chung (`.ai-knowledge/common/`) và thông tin riêng của chính nó (ví dụ: `.ai-knowledge/devin/`).

Thông tin chung được chia thành thông tin riêng cho từng repository (`repo-specific/`) và thông tin dùng chung giữa các repository (`repo-shared.md`).

Các tệp cấu hình hiện có (`.devin/knowledge.md`, `.cursorrules`, `.clinerules`) đã được cập nhật để tham chiếu đến cấu trúc mới này.

