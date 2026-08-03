# xiantang.github.io

blog
<https://vim0.com/>
主要是一些对于平时工作的总结与分享，输出知识是学习的最好手段。

* bash cardimg.sh (filename without extension)
* bash sync.sh  (commit and push to github)

## 本地开发

主题通过 git submodule 引入，首次 clone 后需要拉取，否则页面会是空白：

```bash
git submodule update --init --recursive
```

然后 `docker compose up`，访问 <http://localhost:1313>。


## 图片 
需要保证所有图片都在 `content/image` 目录下面，添加 image checker
引用方式 

`![学习金字塔](/image/the_cone_of_learning.png)`

- [ ] todo 迁移所有图片到 content/image 目录下面，使用脚本迁移
- [x] todo pipeline 上配上图片检查

