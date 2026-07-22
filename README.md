# icdss-basic

ICDSS 基础运行镜像（独立仓库）：**OpenJDK 8 + LibreOffice + Anaconda3**。

仓库：https://github.com/project-icdss/icdss-basic  
镜像：`ghcr.io/project-icdss/icdss-basic`

由原 `icdss/deploy/basic` 拆分而来，通过 GitHub Actions 构建并推送到 GitHub Container Registry (GHCR)。

## 镜像内容

| 组件 | 说明 |
|------|------|
| CentOS 7.9 | 基础系统（yum 源指向 vault） |
| OpenJDK 8 | 运行时 + devel |
| LibreOffice | headless + 中文语言包 |
| Anaconda3 2023.09-0 | 含 SHA256 校验 |
| PyMySQL / python-Levenshtein | pip 安装 |

## 本地构建

```bash
docker build -t icdss-basic:1.0 .

# 国内 PyPI
docker build -t icdss-basic:1.0 \
  --build-arg PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple \
  .
```

## 使用镜像

```bash
docker pull ghcr.io/project-icdss/icdss-basic:latest
docker run --rm -it ghcr.io/project-icdss/icdss-basic:latest java -version
```

在业务 Dockerfile 中：

```dockerfile
FROM ghcr.io/project-icdss/icdss-basic:latest
# 拷贝并启动应用...
```

## GitHub Actions

工作流文件：[`.github/workflows/docker-publish.yml`](.github/workflows/docker-publish.yml)

| 触发条件 | 行为 |
|----------|------|
| push `main` / `master` | 构建并推送 `latest`、`sha-*`、分支 tag |
| push `v*` 标签 | 构建并推送 semver 标签（如 `v1.0.0` → `1.0.0`） |
| pull_request | 仅构建，不推送 |
| workflow_dispatch | 手动构建，可指定 `PIP_INDEX_URL` |

### 首次使用注意

1. 仓库 **Settings → Actions → General**：允许读写 Packages（workflow 已声明 `packages: write`）
2. 若镜像需组织内可见：Packages 页面设置可见性
3. 拉取私有包时：

```bash
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
```

## 与主项目关系

主业务仓库 `icdss` 的应用镜像应 `FROM ghcr.io/project-icdss/icdss-basic:...`，不再在业务仓内维护此 Dockerfile。
