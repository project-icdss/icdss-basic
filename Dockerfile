# ICDSS 基础镜像：Java 8 + LibreOffice + Anaconda（全部从互联网安装）
#
# 本地构建：
#   docker build -t icdss-basic:1.0 .
#
# 可选构建参数：
#   --build-arg CONDA_VERSION=2023.09-0
#   --build-arg PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple

FROM centos:centos7.9.2009

LABEL org.opencontainers.image.title="icdss-basic" \
      org.opencontainers.image.description="ICDSS 基础运行环境（Java8 / LibreOffice / Anaconda）" \
      org.opencontainers.image.source="https://github.com/project-icdss/icdss-basic" \
      maintainer="icdss" \
      version="1.0"

ARG CONDA_VERSION=2023.09-0
# Anaconda3-2023.09-0-Linux-x86_64.sh 官方 SHA256
ARG CONDA_SHA256=6c8a4abb36fbb711dc055b7049a23bbfd61d356de9468b41c5140f8a11abd851
ARG PIP_INDEX_URL=https://pypi.org/simple
ARG TZ=Asia/Shanghai

ENV CONDA_DIR=/opt/anaconda3 \
    JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=${TZ} \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# ---------- CentOS 7 已 EOL：切换 vault 源 ----------
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*.repo \
    && sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*.repo \
    && yum clean all \
    && yum makecache fast

# ---------- 系统基础包、时区、中文字体、编译依赖 ----------
RUN yum install -y \
        ca-certificates \
        openssl \
        wget \
        curl \
        tar \
        gzip \
        bzip2 \
        which \
        tzdata \
        fontconfig \
        liberation-fonts \
        dejavu-sans-fonts \
        wqy-microhei-fonts \
        wqy-zenhei-fonts \
        gcc \
        gcc-c++ \
        make \
    && ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo "${TZ}" > /etc/timezone \
    && localedef -c -f UTF-8 -i en_US en_US.UTF-8 || true \
    && localedef -c -f UTF-8 -i zh_CN zh_CN.UTF-8 || true \
    && yum clean all \
    && rm -rf /var/cache/yum /tmp/* /var/tmp/*

# ---------- Java 8 ----------
RUN yum install -y \
        java-1.8.0-openjdk \
        java-1.8.0-openjdk-devel \
    && yum clean all \
    && rm -rf /var/cache/yum \
    && java -version \
    && javac -version

ENV PATH=${JAVA_HOME}/bin:${PATH}

# ---------- LibreOffice（文档转换，含无头模式与中文语言包） ----------
RUN yum install -y \
        libreoffice \
        libreoffice-headless \
        libreoffice-writer \
        libreoffice-calc \
        libreoffice-impress \
        libreoffice-math \
        libreoffice-langpack-zh-Hans \
    && yum clean all \
    && rm -rf /var/cache/yum /tmp/* /var/tmp/* \
    && (command -v libreoffice >/dev/null || ln -sf /usr/bin/soffice /usr/local/bin/libreoffice) \
    && soffice --version

# ---------- 从官网下载并校验安装 Anaconda ----------
RUN set -eux \
    && curl -fsSL -o /tmp/anaconda.sh \
        "https://repo.anaconda.com/archive/Anaconda3-${CONDA_VERSION}-Linux-x86_64.sh" \
    && echo "${CONDA_SHA256}  /tmp/anaconda.sh" | sha256sum -c - \
    && bash /tmp/anaconda.sh -b -p "${CONDA_DIR}" \
    && rm -f /tmp/anaconda.sh \
    && "${CONDA_DIR}/bin/conda" clean -afy \
    && "${CONDA_DIR}/bin/conda" config --system --set show_channel_urls yes \
    && "${CONDA_DIR}/bin/conda" config --system --set auto_update_conda false \
    && ln -sf "${CONDA_DIR}/bin/conda" /usr/local/bin/conda \
    && ln -sf "${CONDA_DIR}/bin/python" /usr/local/bin/python \
    && ln -sf "${CONDA_DIR}/bin/pip" /usr/local/bin/pip \
    && ln -sf "${CONDA_DIR}/bin/python" /usr/local/bin/python3 \
    && rm -rf /tmp/* /var/tmp/* \
    && python --version \
    && conda --version

ENV PATH=${CONDA_DIR}/bin:${PATH}

# ---------- Python 依赖（PyPI，可通过 PIP_INDEX_URL 换国内源） ----------
RUN pip install --no-cache-dir -i "${PIP_INDEX_URL}" \
        PyMySQL \
        python-Levenshtein \
    && python -c "import pymysql; import Levenshtein; print('Python deps OK')" \
    && rm -rf /root/.cache/pip /tmp/* /var/tmp/*

# ---------- 最终环境自检 ----------
RUN set -eux \
    && java -version \
    && javac -version \
    && soffice --version \
    && python -c "import pymysql, Levenshtein" \
    && echo "===== ICDSS basic image ready ====="

WORKDIR /opt/icdss

CMD ["/bin/bash"]
