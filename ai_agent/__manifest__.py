# -*- coding: utf-8 -*-
##############################################################################
#
#    Copyright (C) {year} {company} (<{mail}>)
#    All Rights Reserved
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as published
#    by the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
##############################################################################
#
# https://www.odoo.com/documentation/14.0/reference/module.html
#
{
    'name': "odoo-ai: AI Agent",
    'version': "1.0",
    'summary': "AI Agent orchestration",
    'category': "Productivity",
    'description': """
        
        
AI代理编排是管理和协调多个专业AI代理以实现复杂任务和共享目标的过程。
这种方法允许各种AI代理的无缝协作，每个代理都为特定功能而设计，以高效地协同工作。

AI代理是一种软件系统，它使用人工智能技术来解释信息、做出决策和采取行动。
这些代理可以专门用于特定任务，由大型语言模型（LLM）提供支持，并配备内存功能
（短期和长期，包括检索增强生成或RAG）。
他们还可以使用各种工具与他们的环境进行交互并实现他们的目标。

在这个实现中，这些#修正拼写错误->这些
目标被称为任务。任务可以是人工智能助手、自主工作的人工智能人员或其他东西。#修正拼写自动->自主

##AI编排的关键方面

1.**任务分配**：根据任务的专业能力将任务分配给最合适的AI任务。初始化可能由收到的电子邮件等事件触发

2.**通信**：启用有效的通信渠道、专门的AI聊天机器人或与Odoo对象聊天（例如帮助台票证或项目任务）。#修正helddesk->帮助台

3.**绩效监控**：持续跟踪个人和系统范围的绩效。

##AI代理编排的动机

-**提高效率**：通过利用多个专业代理的优势，组织可以比使用单个代理更有效地应对复杂的挑战。

-**可扩展性**：编排允许根据需要无缝集成其他代理，使系统能够处理不断增加的工作负载和复杂性。

-**灵活性**：组合不同类型代理（例如，简单反射、基于目标的学习代理）的能力允许更具适应性和健壮的AI系统。

##与业务系统集成

无需导出敏感数据即可将AI代理编排与Odoo等业务系统集成。这种方法确保了数据隐私和
安全性，同时仍将AI的力量用于业务流程。AI任务可以直接在ERP系统中交付结果。

##LLM不可知论和开源模型

与LLM无关并利用开源模型对于以下方面至关重要：

1.**灵活性**：允许组织根据其需求和绩效在不同的LLM之间切换。
2.**Cost-effectiveness**：开源模型可以减少对专有解决方案的依赖。
3.**定制**：支持针对特定业务需求的微调模型，而无需供应商锁定。

##成本监控和全公司范围的人工智能使用

跟踪令牌使用情况和监控整个组织的AI使用情况对于以下方面至关重要：

1.**成本管理**：了解和控制与人工智能使用相关的费用。
2.**资源分配**：根据使用模式和需求优化AI资源的分配。
3.**性能评估**：评估人工智能实施的有效性和效率。

通过考虑这些因素实施AI代理编排，组织可以创建强大、灵活、
以及具有成本效益的人工智能系统，可推动其运营的创新和效率。

        sudo apt-get install graphviz graphviz-dev

    """,
    'author': "Vertel AB",
    'website': "https://vertel.se/apps/odoo-ai/ai_agent",
    'images': ["static/description/banner.png"],  # 560x280
    "license": "AGPL-3",
    "depends": ["mail", "product", "crm"],
    "data": [
        "security/ir.model.access.csv",
        "data/server_action.xml",
        "data/data.xml",
        "data/open_ai_data.xml",
        "data/mistral_data.xml",
        "data/anthropic_data.xml",
        "data/azure_data.xml",
        "data/grok_data.xml",
        "data/groq_data.xml",
        "data/google_data.xml",
        "data/huggingface_data.xml",
        "data/ai_agent_data.xml",
        "data/ai_tool_data.xml",
        "demo/ai_agent_demo.xml",
        "wizard/ai_agent_test_wizard_views.xml",
        "wizard/ai_quest_test_mail_wizard_views.xml",
        "wizard/ai_memory_test_wizard_views.xml",
        "views/ai_quest_views.xml",
        "views/ai_agent_views.xml",
        "views/ai_agent_llm_views.xml",
        "views/ai_quest_session_views.xml",
        "views/ai_quest_session_line_views.xml",
        "views/ai_quest_session_message_views.xml",
        "views/ai_memory_views.xml",
        "views/ai_tool_views.xml",
        "views/product_template_views.xml",
        "views/res_company_views.xml",
        "views/res_users_views.xml",
        "views/mail_channel_views.xml",
        "views/res_config_settings_views.xml"
    ],
    "external_dependencies": {
        "python": [
            "langchain-core",
            "markdown",
            "unidecode",
            "IPython",
            "langchain",
            "langgraph",
            "langchain-community",
            "langchain-openai",
            "langchain-mistralai",
            "langchain-groq",
            "langchain-anthropic",
            "langchain-huggingface",
            "pymupdf",
            "faiss",
            "markdownify",
        ],
    },
    'assets': {
        'web.assets_backend': [
            'ai_agent/static/src/js/quest_plugin.js',

            'ai_agent/static/src/js/components/quest_dialog.js',
            'ai_agent/static/src/js/components/quest_prompt_dialog.js',
            'ai_agent/static/src/js/components/quest_prompt_dialog.xml',

            'ai_agent/static/src/js/components/quest_selector_dialog.xml',
            'ai_agent/static/src/js/components/quest_selector_dialog.js',
        ]
    },
    "demo": [],
    "application": True,
    "installable": True,
    "auto_install": False,
    # "post_init_hook": "post_init_hook",
}
