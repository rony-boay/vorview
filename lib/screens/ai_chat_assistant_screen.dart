import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AIChatAssistantScreen extends StatefulWidget {
  final String? teamId;
  final String? serviceOrderId;

  const AIChatAssistantScreen({
    Key? key,
    this.teamId,
    this.serviceOrderId,
  }) : super(key: key);

  @override
  _AIChatAssistantScreenState createState() => _AIChatAssistantScreenState();
}

class _AIChatAssistantScreenState extends State<AIChatAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
    // Add welcome message
    _addMessage(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: "Hi! I'm your AI collaboration assistant. I can help you with team coordination, quality checks, and finding the right collaborators. How can I assist you today?",
      isFromAI: true,
      timestamp: DateTime.now(),
    ));
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Add user message
    _addMessage(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isFromAI: false,
      timestamp: DateTime.now(),
    ));

    _messageController.clear();
    setState(() => _isTyping = true);

    // Simulate AI processing and response
    await Future.delayed(Duration(seconds: 2));
    
    final aiResponse = await _generateAIResponse(text);
    _addMessage(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: aiResponse,
      isFromAI: true,
      timestamp: DateTime.now(),
    ));

    setState(() => _isTyping = false);
  }

  Future<String> _generateAIResponse(String userMessage) async {
    final message = userMessage.toLowerCase();

    // Simple AI response logic - can be enhanced with actual AI/ML
    if (message.contains('team') || message.contains('collaborate')) {
      return "I can help you find team members! Based on your skills and project needs, I'll suggest the best collaborators. Would you like me to analyze your current project requirements?";
    } else if (message.contains('quality') || message.contains('check')) {
      return "I'll perform a quality check on your deliverables. I can analyze completion rates, delivery times, and client satisfaction. Would you like me to review a specific project?";
    } else if (message.contains('match') || message.contains('find')) {
      return "Let me find the perfect matches for you! I'll analyze skills, availability, ratings, and past collaboration success. What type of collaborator are you looking for?";
    } else if (message.contains('service') || message.contains('offer')) {
      return "I can help you optimize your service offerings! I'll analyze market demand, pricing strategies, and skill gaps. Would you like recommendations for new services to offer?";
    } else if (message.contains('problem') || message.contains('issue')) {
      return "I'm here to help resolve any collaboration issues. I can mediate disputes, suggest alternatives, or find replacement team members. What specific problem are you facing?";
    } else {
      return "I understand you're looking for assistance with collaboration. I can help with team formation, quality assurance, skill matching, and project coordination. Could you be more specific about what you need help with?";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.psychology,
                color: Color(0xFF191970),
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Online',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Color(0xFF191970),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onPressed: _showOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isFromAI 
            ? MainAxisAlignment.start 
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isFromAI) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(0xFF191970),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.psychology,
                color: Colors.white,
                size: 16,
              ),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isFromAI 
                    ? Colors.grey[100] 
                    : Color(0xFF191970),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isFromAI 
                          ? Colors.black87 
                          : Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: message.isFromAI 
                          ? Colors.grey[500] 
                          : Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!message.isFromAI) ...[
            SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: Colors.grey[600],
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Color(0xFF191970),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.psychology,
              color: Colors.white,
              size: 16,
            ),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                SizedBox(width: 4),
                _buildDot(1),
                SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 600),
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Ask me anything about collaboration...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Color(0xFF191970),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.refresh, color: Color(0xFF191970)),
              title: Text('Reset Conversation'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _messages.clear();
                  _initializeChat();
                });
              },
            ),
            ListTile(
              leading: Icon(Icons.help, color: Color(0xFF191970)),
              title: Text('Help & Tips'),
              onTap: () {
                Navigator.pop(context);
                _showHelpDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('AI Assistant Help'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('I can help you with:'),
            SizedBox(height: 8),
            Text('• Finding team members'),
            Text('• Quality checking deliverables'),
            Text('• Skill matching and recommendations'),
            Text('• Resolving collaboration issues'),
            Text('• Optimizing service offerings'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String id;
  final String text;
  final bool isFromAI;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isFromAI,
    required this.timestamp,
  });
}