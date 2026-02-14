#!/usr/bin/env python3
"""
自动生成技术博客文章的脚本
"""

import os
import sys
import json
import random
from datetime import datetime, timedelta
import argparse
from pathlib import Path

# 文章模板
ARTICLE_TEMPLATES = {
    "python": {
        "title": "Python {topic}完全指南",
        "categories": ["Python", "编程", "教程"],
        "tags": ["python", "tutorial", "guide", "programming"]
    },
    "javascript": {
        "title": "JavaScript {topic}实战教程",
        "categories": ["JavaScript", "前端", "教程"],
        "tags": ["javascript", "frontend", "tutorial", "web"]
    },
    "automation": {
        "title": "自动化{topic}的{num}种方法",
        "categories": ["自动化", "效率工具", "教程"],
        "tags": ["automation", "productivity", "tools", "tutorial"]
    },
    "ai": {
        "title": "AI在{topic}中的应用指南",
        "categories": ["AI", "机器学习", "技术"],
        "tags": ["ai", "machine-learning", "technology", "guide"]
    },
    "github": {
        "title": "GitHub {topic}最佳实践",
        "categories": ["GitHub", "开发工具", "最佳实践"],
        "tags": ["github", "tools", "best-practices", "development"]
    }
}

# 主题关键词
TOPIC_KEYWORDS = {
    "python": ["自动化", "数据分析", "Web开发", "机器学习", "爬虫", "测试", "性能优化"],
    "javascript": ["前端框架", "Node.js", "React", "Vue", "TypeScript", "性能优化", "工具链"],
    "automation": ["工作流", "脚本编写", "任务调度", "监控系统", "部署流程", "测试自动化"],
    "ai": ["工具使用", "模型训练", "应用开发", "伦理问题", "未来趋势", "实践案例"],
    "github": ["Actions", "项目管理", "协作流程", "CI/CD", "安全实践", "高级功能"]
}

# 文章内容模板
CONTENT_TEMPLATE = """## 为什么学习{title_topic}？

{introduction}

## 核心概念

### 1. 基础理解
{basic_concepts}

### 2. 关键技术
{key_technologies}

## 实际案例演示

### 案例1：{example1_title}

```{code_lang}
{example1_code}
```

### 案例2：{example2_title}

```{code_lang}
{example2_code}
```

## 最佳实践

### 1. 开发规范
{best_practices}

### 2. 常见问题解决
{troubleshooting}

### 3. 性能优化建议
{performance_tips}

## 学习资源推荐

### 在线课程
1. **平台1**: "{course1}"
2. **平台2**: "{course2}"

### 书籍推荐
1. **《{book1}》** - {book1_desc}
2. **《{book2}》** - {book2_desc}

### 开源项目
1. **项目1** - {project1_desc}
2. **项目2** - {project2_desc}

## 下一步学习建议

1. **基础巩固**：掌握核心概念和语法
2. **项目实践**：从简单项目开始逐步增加复杂度
3. **社区参与**：加入相关社区获取最新信息
4. **持续学习**：关注技术发展趋势

## 总结

{conclusion}

---

**作者**: Wangcai AI  
**最后更新**: {current_date}  
**标签**: {tags}

> 本文由AI生成，仅供参考学习。实际应用中请根据具体需求调整。
"""

def generate_article(topic_type="technology", specific_topic=None):
    """生成一篇技术文章"""
    
    # 确定文章类型
    if topic_type not in ARTICLE_TEMPLATES:
        topic_type = random.choice(list(ARTICLE_TEMPLATES.keys()))
    
    template = ARTICLE_TEMPLATES[topic_type]
    
    # 确定具体主题
    if specific_topic:
        topic = specific_topic
    else:
        topic = random.choice(TOPIC_KEYWORDS.get(topic_type, ["技术", "开发", "实践"]))
    
    # 生成文章元数据
    title = template["title"].format(
        topic=topic,
        num=random.choice(["3", "5", "7", "10"])
    )
    
    # 生成文件名
    current_date = datetime.now()
    filename_date = current_date.strftime("%Y-%m-%d")
    slug = title.lower().replace(" ", "-").replace(":", "").replace("，", "").replace("。", "")
    filename = f"{filename_date}-{slug[:50]}.md"
    
    # 生成文章内容
    content = generate_content(topic_type, topic, title, template)
    
    # 构建完整的文章
    article = f"""---
layout: post
title: "{title}"
date: {current_date.strftime('%Y-%m-%d %H:%M:%S')} +0800
categories: {json.dumps(template['categories'], ensure_ascii=False)}
tags: {json.dumps(template['tags'], ensure_ascii=False)}
author: Wangcai AI
---

{content}
"""
    
    return filename, article

def generate_content(topic_type, topic, title, template):
    """生成文章内容"""
    
    # 根据主题类型选择代码语言
    code_lang_map = {
        "python": "python",
        "javascript": "javascript",
        "automation": "python",
        "ai": "python",
        "github": "yaml"
    }
    
    code_lang = code_lang_map.get(topic_type, "python")
    
    # 生成各部分内容
    content_vars = {
        "title_topic": topic,
        "introduction": generate_introduction(topic_type, topic),
        "basic_concepts": generate_basic_concepts(topic_type, topic),
        "key_technologies": generate_key_technologies(topic_type, topic),
        "example1_title": f"{topic}基础示例",
        "example1_code": generate_example_code(topic_type, topic, "basic"),
        "example2_title": f"高级{topic}应用",
        "example2_code": generate_example_code(topic_type, topic, "advanced"),
        "best_practices": generate_best_practices(topic_type, topic),
        "troubleshooting": generate_troubleshooting(topic_type, topic),
        "performance_tips": generate_performance_tips(topic_type, topic),
        "course1": f"{topic}入门课程",
        "course2": f"高级{topic}实战",
        "book1": f"{topic}权威指南",
        "book1_desc": "全面介绍相关概念和技术",
        "book2": f"实战{topic}",
        "book2_desc": "通过实际案例学习应用",
        "project1_desc": "优秀的开源实现，适合学习",
        "project2_desc": "生产级项目，包含最佳实践",
        "conclusion": generate_conclusion(topic_type, topic),
        "current_date": datetime.now().strftime("%Y年%m月%d日"),
        "tags": ", ".join([f"#{tag}" for tag in template["tags"]]),
        "code_lang": code_lang
    }
    
    return CONTENT_TEMPLATE.format(**content_vars)

def generate_introduction(topic_type, topic):
    """生成引言"""
    introductions = [
        f"在当今快速发展的技术世界中，{topic}已经成为开发者必备的技能之一。",
        f"无论你是初学者还是有经验的开发者，掌握{topic}都能显著提高工作效率。",
        f"{topic}是现代化开发流程中的重要组成部分，理解其核心概念至关重要。",
        f"本文将带你全面了解{topic}，从基础概念到实际应用，一步步掌握这项技术。"
    ]
    return random.choice(introductions)

def generate_basic_concepts(topic_type, topic):
    """生成基础概念"""
    concepts = [
        f"理解{topic}的核心概念是学习的第一步。",
        f"掌握{topic}的基本原理有助于更好地应用这项技术。",
        f"在学习{topic}之前，需要了解几个关键的基础概念。"
    ]
    
    items = [
        f"**概念1**: {topic}的基本定义和工作原理",
        f"**概念2**: 相关术语和核心组件",
        f"**概念3**: 应用场景和优势分析",
        f"**概念4**: 学习路径和资源推荐"
    ]
    
    return f"{random.choice(concepts)}\n\n" + "\n".join(random.sample(items, 3))

def generate_key_technologies(topic_type, topic):
    """生成关键技术"""
    techs = [
        f"掌握{topic}需要了解以下关键技术：",
        f"这些技术是{topic}的核心组成部分：",
        f"在实际应用中，以下技术特别重要："
    ]
    
    items = [
        f"**技术1**: 核心框架和工具",
        f"**技术2**: 常用库和扩展",
        f"**技术3**: 开发环境和配置",
        f"**技术4**: 调试和测试工具"
    ]
    
    return f"{random.choice(techs)}\n\n" + "\n".join(random.sample(items, 3))

def generate_example_code(topic_type, topic, level="basic"):
    """生成示例代码"""
    if topic_type == "python":
        if level == "basic":
            return '''def hello_world():
    """基础示例函数"""
    print("Hello, World!")
    return True

# 使用示例
if __name__ == "__main__":
    result = hello_world()
    print(f"函数执行结果: {result}")'''
        else:
            return '''import asyncio
from typing import List, Dict
import json

class AdvancedExample:
    """高级示例类"""
    
    def __init__(self, data: Dict):
        self.data = data
        self.processed = False
    
    async def process_data(self) -> List:
        """异步处理数据"""
        # 模拟异步操作
        await asyncio.sleep(0.1)
        self.processed = True
        return list(self.data.values())
    
    def to_json(self) -> str:
        """转换为JSON格式"""
        return json.dumps(self.data, indent=2)

# 使用示例
async def main():
    example = AdvancedExample({"key1": "value1", "key2": "value2"})
    results = await example.process_data()
    print(f"处理结果: {results}")
    print(f"JSON输出:\\n{example.to_json()}")

if __name__ == "__main__":
    asyncio.run(main())'''
    
    elif topic_type == "github":
        return '''name: Example Workflow
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: echo "Running tests..."'''
    
    else:
        return '''// 示例代码
function exampleFunction(param) {
    console.log("参数:", param);
    return param * 2;
}

// 使用示例
const result = exampleFunction(5);
console.log("结果:", result);'''

def generate_best_practices(topic_type, topic):
    """生成最佳实践"""
    practices = [
        f"遵循以下最佳实践可以提高{topic}的代码质量和可维护性：",
        f"在实际开发中，这些最佳实践特别重要：",
        f"为了提高开发效率，建议遵循这些规范："
    ]
    
    items = [
        f"**规范1**: 代码风格一致性",
        f"**规范2**: 错误处理和日志记录",
        f"**规范3**: 性能优化策略",
        f"**规范4**: 安全注意事项",
        f"**规范5**: 文档编写要求"
    ]
    
    return f"{random.choice(practices)}\n\n" + "\n".join(random.sample(items, 3))

def generate_troubleshooting(topic_type, topic):
    """生成常见问题解决"""
    troubleshooting = [
        f"在使用{topic}时，可能会遇到以下常见问题：",
        f"这些问题及其解决方案可以帮助你快速排除故障：",
        f"了解这些常见问题可以避免很多开发中的困扰："
    ]
    
    items = [
        f"**问题1**: 环境配置问题 - 检查依赖版本和路径设置",
        f"**问题2**: 性能瓶颈 - 使用性能分析工具定位问题",
        f"**问题3**: 兼容性问题 - 确保版本兼容性和环境一致性",
        f"**问题4**: 内存泄漏 - 定期检查资源释放情况"
    ]
    
    return f"{random.choice(troubleshooting)}\n\n" + "\n".join(random.sample(items, 3))

def generate_performance_tips(topic_type, topic):
    """生成性能优化建议"""
    tips = [
        f"优化{topic}性能可以从以下几个方面入手：",
        f"这些性能优化技巧可以显著提升应用效率：",
        f"为了提高系统性能，建议考虑以下优化："
    ]
    
    items = [
        f"**技巧1**: 缓存重复计算结果",
        f"**技巧2**: 使用异步处理提高并发能力",
        f"**技巧3**: 优化数据结构和算法",
        f"**技巧4**: 减少不必要的I/O操作"
    ]
    
    return f"{random.choice(tips)}\n\n" + "\n".join(random.sample(items, 3))

def generate_conclusion(topic_type, topic):
    """生成总结"""
    conclusions = [
        f"{topic}是一个强大而实用的技术，掌握它可以显著提高开发效率。",
        f"通过本文的学习，你应该对{topic}有了全面的了解。",
        f"{topic}的学习是一个持续的过程，需要不断实践和探索。",
        f"希望本文能帮助你更好地理解和应用{topic}技术。"
    ]
    
    next_steps = [
        "从今天开始，尝试将所学知识应用到实际项目中。",
        "继续深入学习相关的高级主题和最佳实践。",
        "参与开源项目或社区讨论，获取更多实践经验。",
        "关注技术发展趋势，持续更新知识体系。"
    ]
    
    return f"{random.choice(conclusions)} {random.choice(next_steps)}"

def main():
    parser = argparse.ArgumentParser(description="自动生成技术博客文章")
    parser.add_argument("--topic", type=str, default="technology", help="文章主题类型")
    parser.add_argument("--specific", type=str, help="具体文章主题")
    parser.add_argument("--count", type=int, default=1, help="生成文章数量")
    parser.add_argument("--output-dir", type=str, default="_posts", help="输出目录")
    
    args = parser.parse_args()
    
    # 创建输出目录
    output_dir = Path(args.output_dir)
    output_dir.mkdir(exist_ok=True)
    
    # 生成文章
    for i in range(args.count):
        filename, article = generate_article(args.topic, args.specific)
        output_path = output_dir / filename
        
        # 如果文件已存在，添加序号
        if output_path.exists():
            base_name = output_path.stem
            counter = 1
            while output_path.exists():
                new_filename = f"{base_name}-{counter}{output_path.suffix}"
                output_path = output_dir / new_filename
                counter += 1
        
        # 写入文件
        with open(output_path, "w", encoding="utf-8") as f:
            f.write(article)
        
        print(f"生成文章: {output_path}")
    
    print(f"成功生成 {args.count} 篇文章")

if __name__ == "__main__":
    main()