import 'package:flutter/material.dart';
import 'package:agri_frontend/service/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../main.dart';

class AiChatPage extends StatefulWidget {
  final String? conversationId;

  const AiChatPage({super.key, this.conversationId});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  String? _currentConversationId;
  String _conversationTitle = '';

  @override
  void initState() {
    super.initState();
    _initializeConversation();
  }

  Future<void> _initializeConversation() async {
    if (widget.conversationId != null) {
      await _loadConversation(widget.conversationId!);
    } else {
      _currentConversationId = DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  Future<void> _loadConversation(String conversationId) async {
    final userId = context.read<UserProvider>().userId;
    try {
      final conversationMessages = await ApiService.getConversation(userId, conversationId);
      if (!mounted) return;

      setState(() {
        _currentConversationId = conversationId;
        _messages.clear();
        for (var msg in conversationMessages) {
          _messages.add({
            'text': msg['message'] ?? msg['text'] ?? '',
            'isUser': msg['is_user'] ?? msg['isUser'] ?? false,
            'sources': msg['sources'] ?? [],
          });
        }
        _updateTitleFromMessages();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('error_loading'.tr())));
        _startNewConversation();
      }
    }
  }

  void _updateTitleFromMessages() {
    if (_messages.isNotEmpty) {
      final firstMsg = _messages.firstWhere((msg) => msg['isUser'] == true, orElse: () => _messages.first);
      final text = firstMsg['text'].toString();
      _conversationTitle = text.length > 50 ? '${text.substring(0, 47)}...' : text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isTyping) return;

    final userId = context.read<UserProvider>().userId;
    _controller.clear();

    setState(() {
      _messages.add({'text': text, 'isUser': true});
      _isTyping = true;
      if (_messages.length == 1) _conversationTitle = text;
    });

    _scrollToBottom();

    try {
      final response = await ApiService.sendMessage(text, userId, _currentConversationId!);
      if (mounted) {
        setState(() {
          _messages.add({
            'text': response['response'] ?? response['message'] ?? '',
            'isUser': false,
            'sources': response['sources'] ?? [],
          });
          _isTyping = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({'text': 'an_error_occurred'.tr(), 'isUser': false, 'isError': true});
          _isTyping = false;
        });
      }
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _startNewConversation() {
    setState(() {
      _messages.clear();
      _currentConversationId = DateTime.now().millisecondsSinceEpoch.toString();
      _conversationTitle = '';
    });
  }

  // --- UI COMPONENTS ---

  Widget _buildMessage(Map<String, dynamic> message, double maxWidth) {
    final isUser = message['isUser'] as bool;
    final isError = message['isError'] as bool? ?? false;
    final sources = (message['sources'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(Icons.auto_awesome, true),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth * 0.75),
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isError ? Colors.red.shade50 : (isUser ? Colors.green.shade600 : Colors.grey.shade100),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 0),
                      bottomRight: Radius.circular(isUser ? 0 : 16),
                    ),
                  ),
                  child: Text(
                    message['text'],
                    style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 14),
                  ),
                ),
                if (!isUser && sources.isNotEmpty) _buildSources(sources),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isUser) _buildAvatar(Icons.person, false),
        ],
      ),
    );
  }

  Widget _buildAvatar(IconData icon, bool isAi) {
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isAi ? LinearGradient(colors: [Colors.purple.shade300, Colors.deepPurple]) : null,
        color: !isAi ? Colors.green.shade100 : null,
      ),
      child: Icon(icon, color: isAi ? Colors.white : Colors.green.shade700, size: 18),
    );
  }

  Widget _buildSources(List<Map<String, dynamic>> sources) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        children: sources.map((s) => ActionChip(
          label: Text(s['title'] ?? 'Link', style: const TextStyle(fontSize: 10)),
          onPressed: () => _launchUrl(s['uri'] ?? ''),
          visualDensity: VisualDensity.compact,
        )).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor : Colors.green.shade700,
        foregroundColor: Colors.white,
        title: Text('ai_assistant_title'.tr(), style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(icon: const Icon(Icons.history), onPressed: _showHistoryPanel),
          IconButton(icon: const Icon(Icons.add), onPressed: _startNewConversation),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty ? _buildEmptyState() : ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) return _buildTypingIndicator();
                return _buildMessage(_messages[index], screenWidth);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildAvatar(Icons.auto_awesome, true),
          const SizedBox(width: 10),
          const Text('...', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, size: 60, color: Colors.purple),
          const SizedBox(height: 16),
          Text('how_can_i_help'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(hintText: 'your_question'.tr(), border: InputBorder.none),
              maxLines: 4, minLines: 1,
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: _isTyping ? Colors.grey : Colors.green),
            onPressed: _isTyping ? null : _sendMessage,
          ),
        ],
      ),
    );
  }

  void _showHistoryPanel() {
    final userId = context.read<UserProvider>().userId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FutureBuilder<List<dynamic>>(
          future: ApiService.getAllConversations(userId),
          builder: (context, snapshot) {
            // 🔄 Loading
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            // ❌ Error
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Erreur: ${snapshot.error}",
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final conversations = snapshot.data ?? [];

            // 📭 Empty
            if (conversations.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(30),
                child: Center(
                  child: Text(
                    "Aucune conversation enregistrée 😕",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              );
            }

            // ✅ Conversations list
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  const Text(
                    "📌 Historique des conversations",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),

                  Expanded(
                    child: ListView.builder(
                      itemCount: conversations.length,
                      itemBuilder: (context, index) {
                        final conv = conversations[index];

                        final convId = conv["id"].toString();
                        final title =
                            conv["title"] ?? "Conversation ${index + 1}";

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.chat),

                            title: Text(title),

                            // 🗑 Delete
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final result =
                                await ApiService.deleteConversation(
                                    userId, convId);

                                if (result["success"] == true) {
                                  Navigator.pop(context);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                      Text("Conversation supprimée ✅"),
                                    ),
                                  );

                                  _showHistoryPanel();
                                }
                              },
                            ),

                            // 📌 Load Conversation
                            onTap: () async {
                              Navigator.pop(context);

                              try {
                                final history =
                                await ApiService.getConversation(
                                    userId, convId);

                                setState(() {
                                  _messages.clear();
                                  _currentConversationId = convId;

                                  for (var msg in history) {
                                    _messages.add({
                                      "text": msg["message"] ?? "",
                                      "isUser": msg["is_user"] ?? false,
                                      "sources": msg["sources"] ?? [],
                                    });
                                  }
                                });

                                _scrollToBottom();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Erreur chargement historique"),
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

}