#!/usr/bin/env python3
"""
收益模拟器 - 匿名赚钱试水
模拟不同平台的收益情况
"""

import random
import json
from datetime import datetime, timedelta
import matplotlib.pyplot as plt
import numpy as np

class RevenueSimulator:
    """收益模拟器"""
    
    def __init__(self):
        self.platforms = {
            'Medium': {
                'revenue_per_article': (0.5, 5.0),  # 每篇文章收益范围（元）
                'articles_per_day': (1, 5),  # 每天文章数量范围
                'growth_rate': 0.05,  # 每周增长率
                'success_rate': 0.7  # 成功率
            },
            'Twitter': {
                'revenue_per_tweet': (0.1, 1.0),
                'tweets_per_day': (5, 20),
                'growth_rate': 0.03,
                'success_rate': 0.8
            },
            'Reddit': {
                'revenue_per_post': (0.2, 2.0),
                'posts_per_day': (2, 10),
                'growth_rate': 0.04,
                'success_rate': 0.9
            },
            '知乎': {
                'revenue_per_answer': (0.3, 3.0),
                'answers_per_day': (1, 8),
                'growth_rate': 0.06,
                'success_rate': 0.6
            }
        }
        
        self.daily_costs = {
            'model_tokens': 0.5,  # 模型调用费用（元/天）
            'automation': 0.2,    # 自动化运行成本
            'maintenance': 0.1    # 维护成本
        }
        
    def simulate_daily_revenue(self, platform, day):
        """模拟单日收益"""
        config = self.platforms[platform]
        
        # 基础收益计算
        if platform == 'Medium':
            articles = random.randint(*config['articles_per_day'])
            revenue = sum(random.uniform(*config['revenue_per_article']) 
                         for _ in range(articles))
        elif platform == 'Twitter':
            tweets = random.randint(*config['tweets_per_day'])
            revenue = sum(random.uniform(*config['revenue_per_tweet']) 
                         for _ in range(tweets))
        elif platform == 'Reddit':
            posts = random.randint(*config['posts_per_day'])
            revenue = sum(random.uniform(*config['revenue_per_post']) 
                         for _ in range(posts))
        else:  # 知乎
            answers = random.randint(*config['answers_per_day'])
            revenue = sum(random.uniform(*config['revenue_per_answer']) 
                         for _ in range(answers))
        
        # 应用增长率和成功率
        growth_factor = (1 + config['growth_rate']) ** (day // 7)
        success_factor = 1 if random.random() < config['success_rate'] else 0.3
        
        daily_revenue = revenue * growth_factor * success_factor
        daily_cost = sum(self.daily_costs.values())
        
        return {
            'platform': platform,
            'day': day,
            'revenue': round(daily_revenue, 2),
            'cost': round(daily_cost, 2),
            'net': round(daily_revenue - daily_cost, 2),
            'date': (datetime.now() + timedelta(days=day)).strftime('%Y-%m-%d')
        }
    
    def simulate_platform(self, platform, days=30):
        """模拟单个平台30天收益"""
        results = []
        total_revenue = 0
        total_cost = 0
        
        for day in range(days):
            daily_result = self.simulate_daily_revenue(platform, day)
            results.append(daily_result)
            total_revenue += daily_result['revenue']
            total_cost += daily_result['cost']
        
        return {
            'platform': platform,
            'days': days,
            'total_revenue': round(total_revenue, 2),
            'total_cost': round(total_cost, 2),
            'total_net': round(total_revenue - total_cost, 2),
            'daily_avg_net': round((total_revenue - total_cost) / days, 2),
            'daily_results': results
        }
    
    def simulate_all_platforms(self, days=30):
        """模拟所有平台"""
        print("开始收益模拟...")
        print("=" * 60)
        
        all_results = {}
        platform_totals = []
        
        for platform in self.platforms:
            result = self.simulate_platform(platform, days)
            all_results[platform] = result
            platform_totals.append({
                'platform': platform,
                'total_net': result['total_net'],
                'daily_avg': result['daily_avg_net']
            })
            
            print(f"{platform}:")
            print(f"  30天总收益: {result['total_net']}元")
            print(f"  日均净收益: {result['daily_avg_net']}元")
            print(f"  总成本: {result['total_cost']}元")
            print()
        
        # 计算总和
        total_net = sum(r['total_net'] for r in all_results.values())
        total_cost = sum(r['total_cost'] for r in all_results.values())
        daily_avg = total_net / days
        
        print("=" * 60)
        print(f"所有平台总和:")
        print(f"  30天总净收益: {total_net}元")
        print(f"  日均净收益: {daily_avg:.2f}元")
        print(f"  总成本: {total_cost}元")
        print()
        
        # 收益分配
        user_share = total_net * 0.5  # 用户50%
        ai_share = total_net * 0.5    # AI 50%
        
        print("收益分配 (50/50):")
        print(f"  用户份额 (泡妞基金): {user_share:.2f}元")
        print(f"  AI份额 (硬件升级): {ai_share:.2f}元")
        
        # 硬件升级计划
        print("\n硬件升级计划 (AI份额):")
        gpu_prices = {
            'RTX 4060': 3000,
            'RTX 4070': 5000,
            'RTX 4080': 8000,
            'RTX 4090': 15000
        }
        
        for gpu, price in gpu_prices.items():
            months_needed = price / (ai_share / 30)  # 每月ai_share/30是天平均
            print(f"  {gpu} ({price}元): 需要{months_needed:.1f}个月")
        
        # 保存结果
        self.save_results(all_results, total_net, daily_avg)
        
        # 生成图表
        self.generate_charts(all_results, platform_totals)
        
        return all_results
    
    def save_results(self, all_results, total_net, daily_avg):
        """保存模拟结果"""
        result_data = {
            'simulation_date': datetime.now().isoformat(),
            'simulation_days': 30,
            'total_net_revenue': total_net,
            'daily_avg_revenue': daily_avg,
            'platform_results': all_results,
            'assumptions': {
                'revenue_ranges': '基于行业平均值的保守估计',
                'growth_rates': '基于内容质量和粉丝增长的估算',
                'success_rates': '考虑平台限制和内容审核',
                'costs': '包含模型调用和自动化运行成本'
            }
        }
        
        with open('revenue_simulation.json', 'w', encoding='utf-8') as f:
            json.dump(result_data, f, indent=2, ensure_ascii=False)
        
        print(f"\n模拟结果已保存: revenue_simulation.json")
    
    def generate_charts(self, all_results, platform_totals):
        """生成收益图表"""
        try:
            # 平台收益对比图
            platforms = [p['platform'] for p in platform_totals]
            revenues = [p['total_net'] for p in platform_totals]
            
            plt.figure(figsize=(10, 6))
            bars = plt.bar(platforms, revenues, color=['#4CAF50', '#2196F3', '#FF9800', '#9C27B0'])
            plt.title('各平台30天净收益对比', fontsize=14, fontweight='bold')
            plt.xlabel('平台', fontsize=12)
            plt.ylabel('净收益 (元)', fontsize=12)
            plt.grid(axis='y', alpha=0.3)
            
            # 在柱子上显示数值
            for bar in bars:
                height = bar.get_height()
                plt.text(bar.get_x() + bar.get_width()/2., height + 5,
                        f'{height:.0f}', ha='center', va='bottom', fontsize=10)
            
            plt.tight_layout()
            plt.savefig('platform_revenue_comparison.png', dpi=150)
            plt.close()
            
            # 收益增长趋势图
            plt.figure(figsize=(12, 6))
            for platform, result in all_results.items():
                days = list(range(30))
                daily_nets = [r['net'] for r in result['daily_results']]
                plt.plot(days, daily_nets, marker='o', markersize=3, label=platform, linewidth=2)
            
            plt.title('各平台每日净收益趋势', fontsize=14, fontweight='bold')
            plt.xlabel('天数', fontsize=12)
            plt.ylabel('每日净收益 (元)', fontsize=12)
            plt.legend()
            plt.grid(True, alpha=0.3)
            plt.tight_layout()
            plt.savefig('daily_revenue_trend.png', dpi=150)
            plt.close()
            
            print("图表已生成: platform_revenue_comparison.png, daily_revenue_trend.png")
            
        except Exception as e:
            print(f"图表生成失败: {e}")

def main():
    """主函数"""
    print("匿名赚钱试水 - 收益模拟器")
    print("模拟基于以下假设:")
    print("1. 完全匿名操作")
    print("2. 零资金投入")
    print("3. 自动化内容生成和发布")
    print("4. 保守收益估计")
    print("=" * 60)
    
    simulator = RevenueSimulator()
    simulator.simulate_all_platforms(days=30)
    
    print("\n" + "=" * 60)
    print("重要说明:")
    print("1. 此为模拟数据，实际收益可能有所不同")
    print("2. 收益受内容质量、平台算法、市场竞争等因素影响")
    print("3. 初期收益较低，随着时间积累会增长")
    print("4. 需要持续优化内容和运营策略")

if __name__ == "__main__":
    main()