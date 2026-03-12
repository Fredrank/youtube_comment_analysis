
###
# 业务问题：评论区的互动质量到底怎么样？YouTube 视频评论互动是由广泛用户参与驱动，还是由少数核心用户和核心内容主导？
# 哪些视频真正带动了社区互动？用户互动是否集中在某些内容或话题？

# 痛点：无法判断哪些视频是真正成功的互动内容，难以识别核心粉丝
###

library(vosonSML)
library(VOSONDash)
library(magrittr)
library(igraph)
library(dplyr)
library(ggplot2)

# Step 1: 认证 API
youtubeAuth <- Authenticate("youtube", apiKey = "AIzaSyDnKq-S2DTROatTAuHfqFSbHXtXm9CPlT0")

# Step 2: 视频 ID

# ishowspeed
# videoIDs <- c("https://www.youtube.com/watch?v=wYZux3BMc5k",          # 169620
#               "https://www.youtube.com/watch?v=8n5dJwWXrbo",          # 215681
#               "https://www.youtube.com/watch?v=o5nnBM3WH-Q",          # 66538
#               "https://www.youtube.com/watch?v=9OyT9SlKaFY",          # 33036
#               "https://www.youtube.com/watch?v=8WZ-4JiwFIo",          # 12481
#               "https://www.youtube.com/watch?v=65ZbbS8Xa6w",          # 28552
#               "https://www.youtube.com/watch?v=Fiq9XMRr4jg",          # 74557
#               "https://www.youtube.com/watch?v=KlPmi1YWizc",          # 58990
#               "https://www.youtube.com/watch?v=1-neUvMyGNs",          # 16403
#               "https://www.youtube.com/watch?v=aWKtAqIUEl4")          # 28992

# joshneuman
videoIDs <- c("https://www.youtube.com/watch?v=yn-TfAzobDI&t=92s",    # 65652
              "https://www.youtube.com/watch?v=vSBcrmx4aFw",          # 41893
              "https://www.youtube.com/watch?v=0snMHahKGR8",          # 313856
              "https://www.youtube.com/watch?v=hmWlXEqs_pY&t=4s",     # 9126
              "https://www.youtube.com/watch?v=vqX4w5Ccicg&t=6s",     # 3194
              "https://www.youtube.com/watch?v=JjJHOYIVO98",          # 3867
              "https://www.youtube.com/watch?v=w9o0q4ZaSFw",          # 1505
              "https://www.youtube.com/watch?v=H5Q-GtGIp44",          # 1925
              "https://www.youtube.com/watch?v=0hFzpF_gGys",          # 1366
              "https://www.youtube.com/watch?v=hlzTVBg2LrI")          # 1802

# 数据抓取
# 字段：评论，用户名，用户头像链接，用户频道链接，用户频道ID，回复统计，点赞统计，评论时间，更新时间，评论ID，视频ID
youtubeData <- Collect(credential = youtubeAuth, videoIDs = videoIDs, maxComments = 1000, writeToFile = TRUE)

# ==================================
# Step 3: 数据清洗
# ==================================
# 删除缺失值
edges_weighted <- youtubeData %>%
  filter(!is.na(AuthorDisplayName), !is.na(VideoID)) %>% 
  group_by(User = AuthorDisplayName, Video = VideoID) %>%
  summarise(weight = n(), .groups = "drop")


# 筛选只评论一个视频的用户-过滤一次性噪声
user_video_count <- edges_weighted %>%
  group_by(User) %>%
  summarise(video_count = n_distinct(Video))

active_users <- user_video_count %>%
  filter(video_count >= 2) %>%
  pull(User)

edges_weighted_filtered <- edges_weighted %>%
  filter(User %in% active_users)

# ==================================
# Step 4: 特征工程
# ==================================

# 用户参与度指标
user_metrics <- edges_weighted_filtered %>%
  group_by(User) %>%
  summarise(
    engaged_videos = n_distinct(Video),   # 评论过多少视频（参与广度）
    total_comments = sum(weight),         # 评论总次数（参与强度）
    avg_comments = mean(weight)           # 每个视频平均评论次数
  )

head(user_metrics)

# 用户粘性指标
user_stickiness <- edges_weighted_filtered %>%
  group_by(User) %>%
  mutate(p = weight / sum(weight)) %>%
  summarise(
    top1_share = max(weight) / sum(weight),  # 评论是否集中于某个视频
    hhi = sum(p^2)                           # 评论集中度指数
  )

head(user_stickiness)

# 视频内容表现-体现用户参与度。
video_metrics <- edges_weighted_filtered %>%
  group_by(Video) %>%
  summarise(
    unique_users = n_distinct(User),  # 覆盖用户数
    total_comments = sum(weight),     # 评论总数（热度）
    avg_comments_per_user = total_comments / unique_users # 平均互动
  ) %>%
  arrange(desc(total_comments))

head(video_metrics)

# ==================================
# Step 5: 探索性分析 Exploratory Data Analysis
# ==================================

# 1.用户评论数量分布
ggplot(user_metrics,aes(total_comments)) +
  geom_histogram(bins = 30, fill = "steelblue") +
  labs(title = "Distribution of User Comments", x = "Number of Comments", y = "Number of User")

median(user_metrics$total_comments)
mean(user_metrics$total_comments) # 平均评论数远高于中位数，说明评论行为呈明显长尾分布。
# 用户互动呈明显长尾分布，少数用户贡献大量评论。

# 2.用户参与视频数量分布
ggplot(user_metrics, aes(engaged_videos)) +
  geom_histogram(bins = 10, fill = "orange") +
  labs(title = "Videos Commented per User", x = "Number of Commented Videos", y = "Number of User")
#                                                        参与视频数
# 大部分用户仅参与1-2个视频讨论。

# 3.评论最多的视频
ggplot(video_metrics[1:10,], aes(reorder(Video, total_comments), total_comments)) +
  geom_bar(stat = "identity", fill = "red") +
  coord_flip() +
  labs(title = "Top Videos by Comment Activity", x = "Video ID", y = "Number of Comments")
# 评论互动集中在少数视频：这些视频是真正的社区核心内容。

# 4.用户&视频集中度分析
# =====================
# 评论集中度分析（用户）
# =====================

user_comment_total <- user_metrics %>%
  arrange(desc(total_comments))

total_comments <- sum(user_comment_total$total_comments)

top5_share <- sum(head(user_comment_total$total_comments,5)) / total_comments
top10_share <- sum(head(user_comment_total$total_comments,10)) / total_comments

top5_share
top10_share
# top5用户贡献0.265896，top10用户贡献0.3040462
# ====================
# 视频互动集中度
# ====================

video_comment_total <- video_metrics %>%
  arrange(desc(total_comments))

total_video_comments <- sum(video_comment_total$total_comments)

top3_video_share <- sum(head(video_comment_total$total_comments,3)) /
  total_video_comments

top5_video_share <- sum(head(video_comment_total$total_comments,5)) /
  total_video_comments

top3_video_share
top5_video_share
# top3视频贡献0.4485549，top5视频贡献0.6520231
# ==================================
# Step 6: 网络建模
# ==================================
# 构建用户-视频二模网络
g_bimode <- graph_from_data_frame(edges_weighted_filtered, directed = FALSE)

# 标记节点类型
V(g_bimode)$type <- V(g_bimode)$name %in% edges_weighted_filtered$User

# 添加连续属性: 度数
V(g_bimode)$degree <- degree(g_bimode)

# 计算网络密度
network_density <- edge_density(g_bimode)

# 构建离散属性：活跃等级
user_activity <- youtubeData %>%
  group_by(User = AuthorDisplayName) %>%
  summarise(video_count = n_distinct(VideoID)) %>%
  mutate(active_level = case_when(
    video_count >= 4 ~ "high",
    video_count == 3 ~ "medium",
    TRUE ~ "low"
  ))

# 给每个用户节点赋活跃等级（视频节点为 NA）
V(g_bimode)$active_level <- user_activity$active_level[match(V(g_bimode)$name, user_activity$User)]

table(V(g_bimode)$active_level) # 仅 1.9% 用户跨多个视频持续参与评论。

# 设置颜色
V(g_bimode)$color <- ifelse(V(g_bimode)$active_level == "high", "#e31a1c",
                            ifelse(V(g_bimode)$active_level == "medium","#feb24c" ,
                                   ifelse(V(g_bimode)$active_level == "low","#ffffcc" , "grey70")))  # 视频节点设为灰色
# 分组边权重 → 颜色映射
E(g_bimode)$color <- cut(E(g_bimode)$weight,
                         breaks = c(-Inf, 1, 2, 3, Inf),
                         labels = c("grey", "orange", "red", "darkred"),
                         right = TRUE)

# 强制转为字符（防止 factor 错误）
E(g_bimode)$color <- as.character(E(g_bimode)$color)

# 缩小视频节点（例如固定为 3 或 4）
V(g_bimode)$size <- ifelse(V(g_bimode)$type,
                           log1p(V(g_bimode)$degree) * 3.5 + 0,  # 用户节点：按 degree 缩放
                           5)                                   # 视频节点：固定小尺寸
# 缩小边宽
E(g_bimode)$width <- sqrt(E(g_bimode)$weight) * 1.2

# 设置布局
layout <- layout_with_fr(g_bimode)  # 推荐力导向布局

# ==================================
# Step 7: 可视化（节点形状区分类型，边宽表示权重）
# ==================================
plot(g_bimode,
     layout = layout,
     vertex.shape = ifelse(V(g_bimode)$type, "circle", "square"),
     vertex.color = V(g_bimode)$color,
     vertex.size = V(g_bimode)$size,
     edge.width = E(g_bimode)$width, 
     edge.color = E(g_bimode)$color,
     vertex.label = NA,
     main = "YouTube Comment Network: Users–Videos with Comment Weights and Activity Levels")

# 查看各颜色边的数量，确认是否都被识别
table(E(g_bimode)$color)

# 某些用户参与多个视频，某些视频连接大量用户，说明存在社区核心节点。
# ==================================
# 8 基本网络统计
# ==================================
# 总节点数（所有用户）
vcount(g_bimode)
# 总边数
ecount(g_bimode)
# 查看节点名
V(g_bimode)$name
# 查看边权重的分布
table(E(g_bimode)$weight)
# 查看每个用户的度数（连接个数）
degree(g_bimode)

# 用户评论行为呈明显长尾分布，少数高活跃用户贡献了大部分互动。
# 同时评论互动集中在少数核心视频，这些视频在用户互动网络中具有枢纽作用。

### 建议 ###
# 1.对于平台运营，推荐算法可以优先推广互动密集的视频。
# 2.对于创作者，可以围绕高互动话题制作内容。复用内容结构，实现内容策略优化
# 3.对于平台，可以识别核心互动用户，并提供粉丝徽章，提升评论曝光，增强社区粘性。
