import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme/app_colors.dart';

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text: "Bonjour ! Je suis FinCoach, votre assistant IA de FinSmart. Comment puis-je vous aider aujourd'hui à optimiser votre santé financière ?",
      isUser: false,
      timestamp: '15:20',
    ),
  ];

  final List<String> _suggestedPrompts = [
    "Comment économiser 20 000 FCFA ?",
    "Analyse mes dépenses du mois",
    "Méthode boule de neige dette",
    "Explique-moi la règle 50/30/20"
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final userMsg = _ChatMessage(
      text: text,
      isUser: true,
      timestamp: 'A l\'instant',
    );

    setState(() {
      _messages.add(userMsg);
    });
    _messageController.clear();
    _scrollToBottom();

    _generateAiResponse(text);
  }

  void _generateAiResponse(String userPrompt) async {
    // Show quick AI typing indicator
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    String responseText = "C'est une excellente question. En analysant vos flux actuels, je vous recommande d'examiner de près vos abonnements ou vos dépenses de loisirs (Divertissement) qui approchent de leur seuil critique de 90%.";

    final lowerPrompt = userPrompt.toLowerCase();
    if (lowerPrompt.contains('économiser') || lowerPrompt.contains('epargn')) {
      responseText = "Pour économiser 20 000 FCFA sur un revenu mensuel de 250 000 FCFA, l'idéal est de réduire les sorties de 5 000 FCFA par semaine. Vous pouvez également automatiser un transfert de 20% vers votre objectif 'MacBook' le jour du salaire !";
    } else if (lowerPrompt.contains('dépenses') || lowerPrompt.contains('analyse')) {
      responseText = "Analyse de vos dépenses : Votre catégorie 'Divertissement' (27 500 FCFA dépensés pour 30 000 FCFA max) est à 91.6%. C'est une fuite financière importante ! Essayez de geler ces dépenses pour les 5 prochains jours.";
    } else if (lowerPrompt.contains('dette') || lowerPrompt.contains('boule de neige')) {
      responseText = "La méthode 'boule de neige' consiste à rembourser vos dettes en commençant par la plus petite somme, quel que soit le taux. Cela vous procure une victoire psychologique rapide pour rester motivé !";
    } else if (lowerPrompt.contains('50/30/20') || lowerPrompt.contains('regle')) {
      responseText = "La règle 50/30/20 divise votre revenu en trois catégories : 50% pour les Besoins essentiels (loyer, nourriture), 30% pour les Envies (loisirs, restaurants) et 20% pour l'Épargne ou le remboursement anticipé des dettes.";
    }

    final aiMsg = _ChatMessage(
      text: responseText,
      isUser: false,
      timestamp: 'A l\'instant',
    );

    setState(() {
      _messages.add(aiMsg);
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology_rounded, color: AppColors.accent, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('FinCoach IA'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Ambient glowing indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.darkSurface,
              child: Row(
                children: [
                  Container(
                    height: 8,
                    width: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Propulsé par Gemini 1.5 Flash (Gratuit & Rapide)',
                    style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),

            // Messages View
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return Align(
                    alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: msg.isUser ? AppColors.primary : AppColors.darkSurface,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(msg.isUser ? 20 : 4),
                          bottomRight: Radius.circular(msg.isUser ? 4 : 20),
                        ),
                        border: msg.isUser ? null : Border.all(color: AppColors.darkBorder),
                      ),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.78,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg.text,
                            style: TextStyle(
                              color: msg.isUser ? Colors.black : Colors.white,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              msg.timestamp,
                              style: TextStyle(
                                color: msg.isUser ? Colors.black54 : AppColors.darkTextSecondary,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, end: 0),
                  );
                },
              ),
            ),

            // Suggested Prompts horizontal bar (if only welcome message)
            if (_messages.length == 1)
              Container(
                height: 45,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _suggestedPrompts.length,
                  itemBuilder: (context, index) {
                    final prompt = _suggestedPrompts[index];
                    return GestureDetector(
                      onTap: () => _sendMessage(prompt),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.darkSurface,
                          border: Border.all(color: AppColors.darkBorder),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            prompt,
                            style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Text input controls
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.darkSurface,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: _sendMessage,
                      decoration: const InputDecoration(
                        hintText: 'Posez une question à FinCoach...',
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => _sendMessage(_messageController.text),
                      icon: const Icon(Icons.send_rounded, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final String timestamp;
  _ChatMessage({required this.text, required this.isUser, required this.timestamp});
}
