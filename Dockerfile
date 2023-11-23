# 第一个部分 以MVN_BUILD为别名 使用了maven:3.8.4-openjdk-11作为基础镜像
FROM maven:3.8.4-openjdk-11 as MVN_BUILD
# 设置工作目录为 /opt/solo/
WORKDIR /opt/solo/
# 将当前目录下的所有文件添加到容器的 /tmp 目录中
ADD . /tmp
# 在 /tmp 目录下
# 执行 Maven 命令，通过参数指定跳过测试、激活CI以及安静模式，进行项目打包。
# 然后将生成的目标文件夹 target/solo/* 复制到 /opt/solo/ 目录下
# 将 /tmp/src/main/resources/docker/* 目录下的文件复制到 /opt/solo/ 目录下。
RUN cd /tmp && mvn package -DskipTests -Pci -q && mv target/solo/* /opt/solo/ \
&& cp -f /tmp/src/main/resources/docker/* /opt/solo/

# 第二个部分 openjdk:18-alpine作为基础镜像
FROM openjdk:18-alpine
# LABEL命令用于向镜像添加元数据，通常用来提供关于镜像的描述信息
# 为镜像添加了一个名为"maintainer"的标签，其内容是"name<mail>"，用来指定该镜像的维护者或负责人的联系信息。
LABEL maintainer="JianHua Zhang<amethystfob@163.com>"
# 设置工作目录为 /opt/solo/
WORKDIR /opt/solo/
# 从前一个构建阶段（MVN_BUILD）中复制 /opt/solo/ 目录下的文件到当前镜像的 /opt/solo/ 目录下
COPY --from=MVN_BUILD /opt/solo/ /opt/solo/
# 安装必要的软件包 ca-certificates 和 tzdata，同时不缓存安装包
RUN apk add --no-cache ca-certificates tzdata
# 设置环境变量 TZ 为 Asia/Shanghai
ENV TZ=Asia/Shanghai
# 定义一个构建参数 git_commit，默认值为 0，并将其赋值给环境变量 git_commit
ARG git_commit=0
ENV git_commit=$git_commit
# 暴露容器的端口号 8080
EXPOSE 8080
# 定义容器启动时的入口点（ENTRYPOINT），运行 Java 命令，指定了类路径 -cp 为 lib/*:.，主类为 org.b3log.solo.Server
ENTRYPOINT [ "java", "-cp", "lib/*:.", "org.b3log.solo.Server" ]
