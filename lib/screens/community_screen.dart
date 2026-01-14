// lib/screens/community_screen.dart
import 'package:flutter/material.dart';
import '../models/forum_question.dart';
import '../models/user.dart';
import '../services/forum_service.dart';
import '../widgets/forum_question_card.dart';
import 'forum_question_detail_screen.dart';
import 'forum_create_question_screen.dart';
import 'global_chat_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ForumService _forumService = ForumService();
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = User.currentUser;
    final isGuest = currentUser.id.isEmpty || currentUser.email.isEmpty;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Header with logo and title
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
              child: Row(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.1,
                    height: MediaQuery.of(context).size.width * 0.1,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/itel.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ask ITEL',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          'Get answers from ITEL experts',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Filter button (only for Q&A tab)
                  AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, child) {
                      if (_tabController.index == 0) {
                        return PopupMenuButton<String>(
                          icon: Icon(
                            Icons.filter_list,
                            color: _filterStatus != 'all'
                                ? const Color(0xFF0056AC)
                                : Colors.grey[600],
                          ),
                          onSelected: (value) {
                            setState(() => _filterStatus = value);
                          },
                          itemBuilder: (context) => [
                            _buildFilterItem('all', 'All Questions', Icons.list),
                            _buildFilterItem(
                                'open', 'Open', Icons.help_outline),
                            _buildFilterItem(
                                'resolved', 'Resolved', Icons.check_circle),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),

            // Tab bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF0056AC),
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: const Color(0xFF0056AC),
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.question_answer, size: 20),
                    text: 'Ask ITEL',
                  ),
                  Tab(
                    icon: Icon(Icons.chat, size: 20),
                    text: 'Global Chat',
                  ),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Q&A Forum Tab
                  _buildForumTab(isGuest),
                  // Global Chat Tab
                  const GlobalChatScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          // Only show FAB for Q&A tab and non-guest users
          if (_tabController.index == 0 && !isGuest) {
            return FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ForumCreateQuestionScreen(),
                  ),
                );
              },
              backgroundColor: const Color(0xFF0056AC),
              child: const Icon(Icons.add, color: Colors.white),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  PopupMenuItem<String> _buildFilterItem(
      String value, String label, IconData icon) {
    Color iconColor;
    if (value == 'open') {
      iconColor =
          _filterStatus == 'open' ? const Color(0xFFFF6600) : Colors.grey;
    } else if (value == 'resolved') {
      iconColor = _filterStatus == 'resolved' ? Colors.green : Colors.grey;
    } else {
      iconColor =
          _filterStatus == 'all' ? const Color(0xFF0056AC) : Colors.grey;
    }

    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildForumTab(bool isGuest) {
    return Column(
      children: [
        // Filter indicator
        if (_filterStatus != 'all')
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _filterStatus == 'open'
                        ? Colors.orange[50]
                        : Colors.green[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _filterStatus == 'open'
                          ? Colors.orange[200]!
                          : Colors.green[200]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _filterStatus == 'open'
                            ? Icons.help_outline
                            : Icons.check_circle,
                        size: 14,
                        color: _filterStatus == 'open'
                            ? const Color(0xFFFF6600)
                            : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Showing: ${_filterStatus == 'open' ? 'Open' : 'Resolved'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _filterStatus == 'open'
                              ? const Color(0xFFFF6600)
                              : Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => setState(() => _filterStatus = 'all'),
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: _filterStatus == 'open'
                              ? const Color(0xFFFF6600)
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Questions list (only approved questions)
        Expanded(
          child: StreamBuilder<List<ForumQuestion>>(
            stream: _forumService.getApprovedQuestionsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading questions...'),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading questions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => setState(() {}),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0056AC),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              var questions = snapshot.data ?? [];

              // Apply filter
              if (_filterStatus == 'open') {
                questions = questions
                    .where((q) => q.status == QuestionStatus.open)
                    .toList();
              } else if (_filterStatus == 'resolved') {
                questions = questions
                    .where((q) => q.status == QuestionStatus.resolved)
                    .toList();
              }

              if (questions.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.question_answer_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _filterStatus == 'all'
                              ? 'No questions yet'
                              : 'No $_filterStatus questions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _filterStatus == 'all'
                              ? 'Ask ITEL experts your questions!'
                              : 'Try a different filter',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                        if (!isGuest && _filterStatus == 'all') ...[
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ForumCreateQuestionScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Ask ITEL'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0056AC),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => setState(() {}),
                child: ListView.separated(
                  padding:
                      EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                  itemCount: questions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final question = questions[index];
                    return ForumQuestionCard(
                      question: question,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ForumQuestionDetailScreen(
                              questionId: question.id,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
