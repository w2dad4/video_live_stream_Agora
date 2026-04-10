//隐私设置
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_live_stream/utility/dialogbox.dart';

class PrivacySettingsPage extends ConsumerWidget {
  const PrivacySettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('隐私设置'),
        centerTitle: true,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
      ),
      body: ListView(
        children: [
          // 隐私政策组
          _buildPrivacyGroup([
            SettingsUI.item(
              title: '隐私政策',
              icon: Icons.privacy_tip,
              trailing: '查看',
              onTap: () => context.pushNamed('PrivacyPolicy'), //
            ),
            SettingsUI.divider(),
            SettingsUI.item(
              title: '用户协议',
              icon: Icons.description,
              trailing: '查看',
              onTap: () => context.pushNamed('UserAgreement'), //
            ),
            SettingsUI.divider(),
            SettingsUI.item(
              title: '关于我们',
              icon: Icons.info,
              trailing: '查看',
              onTap: () => context.pushNamed('AboutUs'), //
            ),
          ]),

          // 个人信息保护组
          _buildPrivacyGroup([
            SettingsUI.item(
              title: '个人信息保护',
              icon: Icons.security,
              onTap: () => context.pushNamed('PersonalInfoProtection'), //
            ),
          ]),
        ],
      ),
    );
  }

  // 构建隐私设置组容器
  Widget _buildPrivacyGroup(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
      ),
      child: Column(children: children),
    );
  }
}

///关于我们详情页面
class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('关于我们'),
        centerTitle: true,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.videocam, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '视频直播平台',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF333333)),
                  ),
                  const SizedBox(height: 8),
                  const Text('版本：1.0.0', style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildSection('公司简介', ['我们是一家专注于视频直播服务的科技公司，致力于为用户提供高质量、安全可靠的直播体验。', '通过技术创新和优质服务，我们打造了一个连接内容创作者与观众的互动平台。']),
            const SizedBox(height: 24),
            _buildSection('联系方式', ['• 客服邮箱：support@example.com', '• 商务合作：business@example.com', '• 技术支持：tech@example.com', '• 客服电话：400-123-4567']),
            const SizedBox(height: 24),
            _buildSection('公司地址', ['北京市朝阳区某某大厦', '邮编：100000']),
            const SizedBox(height: 24),
            _buildSection('工作时间', ['• 工作日：9:00-18:00', '• 周末：10:00-17:00', '• 节假日：法定休息']),
            const SizedBox(height: 24),
            _buildSection('社交媒体', ['• 官方微博：@视频直播平台', '• 微信公众号：视频直播', '• 抖音账号：视频直播官方']),
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  const Text('感谢您的使用与支持', style: TextStyle(fontSize: 16, color: Color(0xFF666666))),
                  const SizedBox(height: 8),
                  Text('© 2024 视频直播平台 版权所有', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF333333)),
        ),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(item, style: const TextStyle(fontSize: 14, height: 1.5)),
          ),
        ),
      ],
    );
  }
}

//个人信息保护详情页面
class PersonalInfoProtectionPage extends StatelessWidget {
  const PersonalInfoProtectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('个人信息保护'),
        centerTitle: true,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('我们采取多种措施保护您的个人信息安全，确保您的隐私得到充分保护。', style: TextStyle(fontSize: 14, height: 1.5)),
            const SizedBox(height: 24),
            _buildSection('数据保护措施', ['• 数据加密存储：所有敏感数据采用AES-256加密', '• 访问权限控制：严格的权限管理和身份验证', '• 定期安全检查：每日安全扫描和漏洞检测', '• 匿名化处理：数据分析前进行匿名化处理', '• 最小化收集原则：只收集必要的信息']),
            const SizedBox(height: 24),
            _buildSection('您的权利', ['• 查看个人信息：随时查看我们收集的您的信息', '• 修改错误信息：更新不准确或过时的信息', '• 删除个人数据：在法律允许范围内删除您的数据', '• 撤回授权同意：随时撤回对数据使用的同意', '• 数据导出：申请导出您的个人数据']),
            const SizedBox(height: 24),
            _buildSection('安全承诺', ['• 不向第三方出售您的个人信息', '• 严格遵守相关法律法规', '• 建立完善的安全管理体系', '• 定期进行安全培训和演练', '• 及时响应安全事件和用户投诉']),
            const SizedBox(height: 24),
            _buildSection('联系我们', ['如有任何关于个人信息保护的疑问，请联系：', '• 隐私保护邮箱：privacy@example.com', '• 客服电话：400-123-4567', '• 我们会在24小时内回复您的咨询']),
            const SizedBox(height: 32),
            const Text('最后更新时间：2024年1月1日', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF333333)),
        ),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(item, style: const TextStyle(fontSize: 14, height: 1.5)),
          ),
        ),
      ],
    );
  }
}

//隐私政策详情页面
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('隐私政策'),
        centerTitle: true,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('我们非常重视您的隐私保护，本隐私政策说明了我们如何收集、使用、存储和保护您的个人信息。', style: TextStyle(fontSize: 14, height: 1.5)),
            const SizedBox(height: 24),
            _buildSection('1. 信息收集', ['• 注册信息：用户名、手机号、邮箱等', '• 使用信息：浏览记录、互动数据等', '• 设备信息：设备型号、系统版本等']),
            const SizedBox(height: 24),
            _buildSection('2. 信息使用', ['• 提供服务功能', '• 改善用户体验', '• 安全保护措施']),
            const SizedBox(height: 24),
            _buildSection('3. 信息保护', ['• 数据加密传输', '• 访问权限控制', '• 定期安全审计']),
            const SizedBox(height: 24),
            _buildSection('4. 信息共享', ['• 未经同意不会向第三方共享', '• 法律法规要求除外', '• 合同履行必需的情况']),
            const SizedBox(height: 24),
            _buildSection('5. 用户权利', ['• 查看个人信息', '• 修改错误信息', '• 删除个人数据', '• 撤回授权同意']),
            const SizedBox(height: 24),
            _buildSection('6. 政策更新', ['• 我们会定期更新隐私政策', '• 重大变更会通过应用通知', '• 继续使用即表示同意新政策']),
            const SizedBox(height: 32),
            const Text('最后更新时间：2024年1月1日', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF333333)),
        ),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(item, style: const TextStyle(fontSize: 14, height: 1.5)),
          ),
        ),
      ],
    );
  }
}

//用户协议详情页面
class UserAgreementPage extends StatelessWidget {
  const UserAgreementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('用户协议'),
        centerTitle: true,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('欢迎使用我们的服务！使用本应用即表示您同意以下条款和条件。', style: TextStyle(fontSize: 14, height: 1.5)),
            const SizedBox(height: 24),
            _buildSection('1. 服务条款', ['• 遵守相关法律法规', '• 不得发布违法内容', '• 尊重他人权益', '• 禁止恶意攻击系统']),
            const SizedBox(height: 24),
            _buildSection('2. 用户责任', ['• 保护账号安全', '• 提供真实信息', '• 合理使用服务', '• 及时更新联系方式']),
            const SizedBox(height: 24),
            _buildSection('3. 知识产权', ['• 尊重原创内容', '• 不得侵权使用', '• 遵守授权协议', '• 保护平台知识产权']),
            const SizedBox(height: 24),
            _buildSection('4. 服务限制', ['• 禁止商业滥用', '• 不得传播病毒', '• 禁止垃圾信息', '• 遵守使用规范']),
            const SizedBox(height: 24),
            _buildSection('5. 免责声明', ['• 服务按现状提供', '• 不保证服务连续性', '• 第三方内容责任自负', '• 不可抗力因素除外']),
            const SizedBox(height: 24),
            _buildSection('6. 协议变更', ['• 我们有权修改协议', '• 变更会提前通知', '• 继续使用即表示同意', '• 不同意可停止使用']),
            const SizedBox(height: 32),
            const Text('最后更新时间：2024年1月1日', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF333333)),
        ),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(item, style: const TextStyle(fontSize: 14, height: 1.5)),
          ),
        ),
      ],
    );
  }
}
