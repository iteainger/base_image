### 注意事项
- 在 `__.yaml` 文件中设置 REGISTRY, IMAGE_NAME (应有读写权限)
    - REGISTRY 一般不用设置
- 每个项目放到一个子目录中，每增加一个项目，执行一次 `__ gen` 或者 `nu __.nu`
- 只构建改动的项目
- 构建的镜像名称为 `${REGISTRY}/${IMAGE_NAME}:<dirname>`
    - `__ list` 查看

### 设置 github secrets
#### 创建个人访问令牌
- Settings
- Developer settings
- Personal access tokens
- Fine-grained tokens
- Generate new token

创建后保存

#### 设置令牌
- 仓库 Settings
- Secrets and variables
- Actions
- Secrets
- New repository secret

NAME: GHCR_TOKEN
Secrets: <上一步创建的令牌>

