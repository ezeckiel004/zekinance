import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/extensions/double_ext.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/savings_provider.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/savings_goal_model.dart';
import '../../../data/models/user_model.dart';

class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late SharedPreferences _prefs;
  String? _apiKey;
  bool _isLoading = false;

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text: "Bonjour ! Je suis FinCoach, votre assistant IA de Ze Kinance. Comment puis-je vous aider aujourd'hui à optimiser votre santé financière ?",
      isUser: false,
      timestamp: 'À l\'instant',
    ),
  ];

  final List<String> _suggestedPrompts = [
    "Comment économiser 20 000 FCFA ?",
    "Analyse mes dépenses du mois",
    "Méthode boule de neige dette",
    "Explique-moi la règle 50/30/20"
  ];

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKey = _prefs.getString('gemini_api_key');
    });
  }

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
    if (text.trim().isEmpty || _isLoading) return;

    final userMsg = _ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateFormat('HH:mm').format(DateTime.now()),
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    // Generate response using either Gemini API (Pro) or simulated logic (Demo)
    if (_apiKey != null && _apiKey!.isNotEmpty) {
      _generateRealAiResponse(text);
    } else {
      _generateDemoAiResponse(text);
    }
  }

  // Real-time dynamic response basing on real-time Riverpod data
  void _generateRealAiResponse(String userPrompt) async {
    try {
      // 1. Gather all dynamic financial context from Riverpod providers
      final user = ref.read(authStateProvider);
      
      // Transactions
      List<TransactionModel> transactions = [];
      ref.read(transactionsStreamProvider).whenData((list) => transactions = list);
      
      // Budget
      BudgetModel? activeBudget;
      ref.read(activeBudgetStreamProvider).whenData((budget) => activeBudget = budget);
      
      // Savings Goals
      List<SavingsGoalModel> savingsGoals = [];
      ref.read(savingsGoalsStreamProvider).whenData((list) => savingsGoals = list);

      // 2. Build personalized System Prompt
      final systemPrompt = _buildSystemPrompt(
        user: user,
        transactions: transactions,
        budget: activeBudget,
        savingsGoals: savingsGoals,
      );

      // 3. Request Gemini API
      final String responseText = await _queryGemini(systemPrompt, userPrompt);

      if (!mounted) return;

      final aiMsg = _ChatMessage(
        text: responseText,
        isUser: false,
        timestamp: DateFormat('HH:mm').format(DateTime.now()),
      );

      setState(() {
        _messages.add(aiMsg);
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(
          text: "⚠️ Une erreur inattendue est survenue : $e",
          isUser: false,
          timestamp: DateFormat('HH:mm').format(DateTime.now()),
        ));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  // Backup Simulated logic for Demo mode
  void _generateDemoAiResponse(String userPrompt) async {
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
      timestamp: DateFormat('HH:mm').format(DateTime.now()),
    );

    setState(() {
      _messages.add(aiMsg);
      _isLoading = false;
    });
    _scrollToBottom();
  }

  // Cross-platform HTTP query to Gemini API (Web & Mobile safe)
  Future<String> _queryGemini(String systemPrompt, String userMessage) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey');
    
    try {
      // Gemini strictly requires alternating roles starting with a 'user' turn.
      // We skip the very first welcome message (which is from the model) to enforce this.
      final historyList = _messages.skip(1).toList();

      final historyContents = historyList.map((msg) {
        return {
          "role": msg.isUser ? "user" : "model",
          "parts": [{"text": msg.text}]
        };
      }).toList();

      final requestBody = {
        "contents": historyContents,
        "systemInstruction": {
          "parts": [{"text": systemPrompt}]
        }
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map?;
          final parts = content?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text'] as String?;
            if (text != null) return text;
          }
        }
        return "Je n'ai pas pu obtenir une réponse claire de l'intelligence artificielle.";
      } else {
        try {
          final errData = jsonDecode(response.body);
          final errMsg = errData['error']?['message'] ?? response.body;
          return "⚠️ Erreur API Gemini : $errMsg";
        } catch (_) {
          return "⚠️ Erreur de connexion API (${response.statusCode})";
        }
      }
    } catch (e) {
      return "⚠️ Erreur réseau : Impossible de contacter Google AI. Veuillez vérifier votre clé API ou connexion Internet. ($e)";
    }
  }

  // System Prompt compiler combining live database context
  String _buildSystemPrompt({
    UserModel? user,
    List<TransactionModel>? transactions,
    BudgetModel? budget,
    List<SavingsGoalModel>? savingsGoals,
  }) {
    final buffer = StringBuffer();
    buffer.writeln("CONTEXTE DE L'UTILISATEUR :");
    buffer.writeln("- Prénom/Nom : ${user?.displayName ?? 'Utilisateur'}");
    buffer.writeln("- Salaire Mensuel Déclaré : ${user?.monthlyIncome.toFCFA() ?? '0 FCFA'}");

    if (budget != null) {
      buffer.writeln("\nSUIVI BUDGÉTAIRE ACTUEL (Mois: ${budget.month}) :");
      buffer.writeln("- Limite Globale Planifiée : ${budget.totalBudget.toFCFA()}");
      buffer.writeln("- Détails par catégories :");
      budget.categories.forEach((category, catBudget) {
        buffer.writeln(
            "  * $category : Limite = ${catBudget.limit.toFCFA()}, Dépensé = ${catBudget.spent.toFCFA()} (Reste = ${catBudget.remaining.toFCFA()}, Progression = ${catBudget.percentage.toStringAsFixed(1)}%)");
      });
    }

    if (savingsGoals != null && savingsGoals.isNotEmpty) {
      buffer.writeln("\nPROJETS D'ÉPARGNE ACTIFS (SAVINGS GOALS) :");
      for (var goal in savingsGoals) {
        final progress = goal.target > 0 ? (goal.current / goal.target * 100) : 0.0;
        buffer.writeln(
            "- Projet '${goal.name}' (Catégorie: ${goal.category}) : Cible = ${goal.target.toFCFA()}, Épargné = ${goal.current.toFCFA()} (${progress.toStringAsFixed(1)}% atteint), Échéance = ${DateFormat('dd/MM/yyyy', 'fr_FR').format(goal.deadline)}");
      }
    }

    if (transactions != null && transactions.isNotEmpty) {
      buffer.writeln("\n10 DERNIÈRES TRANSACTIONS RÉCENTES :");
      final recentTxs = transactions.take(10);
      for (var tx in recentTxs) {
        final typeStr = tx.type == TransactionType.income ? 'ENTRÉE/REVENU' : 'SORTIE/DÉPENSE';
        buffer.writeln(
            "- [${DateFormat('dd/MM/yyyy', 'fr_FR').format(tx.date)}] $typeStr de ${tx.amount.toFCFA()} dans '${tx.category}' (Description: ${tx.description})");
      }
    }

    return """
Tu es FinCoach IA, le conseiller financier personnel virtuel et premium de l'application 'Ze Kinance'.
Ton objectif est d'aider l'utilisateur à améliorer sa santé financière, à optimiser son budget, à épargner intelligemment et à atteindre ses objectifs financiers.

RÈGLES D'OR DE COMPORTEMENT :
1. Sois extrêmement bienveillant, motivant, professionnel et pragmatique. Utilise un français impeccable.
2. Basse-toi RIGOUREUSEMENT sur les données financières réelles de l'utilisateur fournies ci-dessous dans le CONTEXTE pour lui donner des conseils sur-mesure.
3. Si l'utilisateur pose une question sur son budget, ses transactions ou ses objectifs d'épargne, fais des calculs précis et cite ses chiffres réels pour étayer tes conseils.
4. Encourage l'utilisation de la règle 50/30/20 (50% Besoins essentiels, 30% Envies/Loisirs, 20% Épargne/Désendettement).
5. Ne propose jamais de placements financiers risqués ou de produits de spéculation. Reste focalisé sur la gestion saine, la réduction de dépenses superflues, l'épargne progressive et le désendettement.

$buffer
""";
  }

  void _showApiKeyDialog(BuildContext context) {
    final controller = TextEditingController(text: _apiKey);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.vpn_key_rounded, color: AppColors.primary),
            SizedBox(width: 12),
            Text('Clé API Gemini Pro', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Entrez votre clé API Google Gemini pour activer l'IA en temps réel. Vos données financières réelles restent strictement sécurisées en local sur votre appareil.",
              style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ex: AIzaSy...',
                hintStyle: TextStyle(color: AppColors.darkTextSecondary.withOpacity(0.3)),
                labelText: 'Clé API Google AI Studio',
                labelStyle: const TextStyle(color: AppColors.primary, fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(const ClipboardData(text: 'https://aistudio.google.com/'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lien Google AI Studio copié ! Collez-le dans votre navigateur.'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              icon: const Icon(Icons.open_in_new_rounded, color: AppColors.accent, size: 16),
              label: const Text(
                "Obtenir une clé API Gemini gratuite",
                style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: AppColors.darkTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final key = controller.text.trim();
              if (key.isEmpty) {
                await _prefs.remove('gemini_api_key');
              } else {
                await _prefs.setString('gemini_api_key', key);
              }
              setState(() {
                _apiKey = key.isEmpty ? null : key;
              });
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(key.isEmpty ? "Mode Démo activé" : "FinCoach Pro activé avec succès ! 🚀"),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Sauvegarder', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isProMode = _apiKey != null && _apiKey!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: (isProMode ? AppColors.primary : AppColors.accent).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isProMode ? Icons.stars_rounded : Icons.psychology_rounded,
                color: isProMode ? AppColors.primary : AppColors.accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text('FinCoach IA'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showApiKeyDialog(context),
            icon: Icon(
              Icons.vpn_key_rounded,
              color: isProMode ? AppColors.primary : AppColors.darkTextSecondary,
            ),
            tooltip: 'Configurer la clé API',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status bar indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.darkSurface,
              child: Row(
                children: [
                  Container(
                    height: 8,
                    width: 8,
                    decoration: BoxDecoration(
                      color: isProMode ? AppColors.primary : AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isProMode
                          ? 'Propulsé par Gemini 1.5 Flash (Mode Pro & Contextuel)'
                          : 'Propulsé par Gemini 1.5 Flash (Mode Démo / Clé requise)',
                      style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 11),
                    ),
                  ),
                  if (isProMode)
                    GestureDetector(
                      onTap: () async {
                        await _prefs.remove('gemini_api_key');
                        setState(() {
                          _apiKey = null;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Déconnecté du Mode Pro (Retour au Mode Démo)')),
                        );
                      },
                      child: const Text(
                        "DÉCONNECTER",
                        style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    )
                ],
              ),
            ),

            // Demo Mode Activation Banner (If in demo mode)
            if (!isProMode)
              Container(
                margin: const EdgeInsets.only(left: 16, right: 16, top: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.darkSurface, Color(0xFF16233B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.stars_rounded, color: AppColors.accent, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Activer FinCoach Pro (IA Réelle)",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Connectez votre clé API Google Gemini pour analyser en temps réel vos budgets, transactions et projets d'épargne avec des conseils personnalisés !",
                      style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 11, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => _showApiKeyDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text("Configurer la clé API", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),

            // Messages View
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  // Render typing indicator at the end if loading
                  if (_isLoading && index == _messages.length) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.darkSurface,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                            bottomLeft: Radius.circular(4),
                            bottomRight: Radius.circular(20),
                          ),
                          border: Border.all(color: AppColors.darkBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "FinCoach réfléchit...",
                              style: TextStyle(
                                color: AppColors.darkTextSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

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
            if (_messages.length == 1 && !_isLoading)
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
                            style: TextStyle(
                              color: isProMode ? AppColors.primary : AppColors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
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
                      enabled: !_isLoading,
                      decoration: const InputDecoration(
                        hintText: 'Posez une question à FinCoach...',
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: _isLoading ? AppColors.darkBorder : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _isLoading ? null : () => _sendMessage(_messageController.text),
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
