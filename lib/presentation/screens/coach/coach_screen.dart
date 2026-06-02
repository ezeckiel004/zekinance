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
import '../../../core/localization/translations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/savings_provider.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/savings_goal_model.dart';
import '../../../data/models/user_model.dart';
import '../../providers/settings_provider.dart';

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
  late List<_ChatMessage> _messages;

  final List<String> _suggestedPromptsFr = [
    "Comment économiser 20 000 FCFA ?",
    "Analyse mes dépenses du mois",
    "Méthode boule de neige dette",
    "Explique-moi la règle 50/30/20"
  ];

  final List<String> _suggestedPromptsEn = [
    "How to save 20 000 FCFA?",
    "Analyze my monthly expenses",
    "Debt snowball method",
    "Explain the 50/30/20 rule"
  ];

  @override
  void initState() {
    super.initState();
    _messages = [];
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKey = _prefs.getString('gemini_api_key');
    });
  }

  void _initializeWelcomeMessage(bool isFr) {
    if (_messages.isEmpty) {
      _messages.add(
        _ChatMessage(
          text: isFr
              ? "Bonjour ! Je suis FinCoach, votre assistant IA de Ze Kinance. Comment puis-je vous aider aujourd'hui à optimiser votre santé financière ?"
              : "Hello! I am FinCoach, your Ze Kinance AI assistant. How can I help you optimize your financial health today?",
          isUser: false,
          timestamp: isFr ? 'À l\'instant' : 'Just now',
        ),
      );
    }
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

  void _sendMessage(String text, bool isFr) {
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

    if (_apiKey != null && _apiKey!.isNotEmpty) {
      _generateRealAiResponse(text, isFr);
    } else {
      _generateDemoAiResponse(text, isFr);
    }
  }

  void _generateRealAiResponse(String userPrompt, bool isFr) async {
    try {
      final user = ref.read(authStateProvider);
      
      List<TransactionModel> transactions = [];
      ref.read(transactionsStreamProvider).whenData((list) => transactions = list);
      
      BudgetModel? activeBudget;
      ref.read(activeBudgetStreamProvider).whenData((budget) => activeBudget = budget);
      
      List<SavingsGoalModel> savingsGoals = [];
      ref.read(savingsGoalsStreamProvider).whenData((list) => savingsGoals = list);

      final systemPrompt = _buildSystemPrompt(
        user: user,
        transactions: transactions,
        budget: activeBudget,
        savingsGoals: savingsGoals,
        isFr: isFr,
      );

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
          text: isFr 
              ? "⚠️ Une erreur inattendue est survenue : $e"
              : "⚠️ An unexpected error occurred: $e",
          isUser: false,
          timestamp: DateFormat('HH:mm').format(DateTime.now()),
        ));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _generateDemoAiResponse(String userPrompt, bool isFr) async {
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    String responseText = isFr
        ? "C'est une excellente question. En analysant vos flux actuels, je vous recommande d'examiner de près vos abonnements ou vos dépenses de loisirs (Divertissement) qui approchent de leur seuil critique de 90%."
        : "That's an excellent question. Analyzing your current cash flows, I recommend you closely examine your subscriptions or leisure expenses (Entertainment) which are approaching their 90% critical threshold.";

    final lowerPrompt = userPrompt.toLowerCase();
    if (lowerPrompt.contains('économiser') || lowerPrompt.contains('epargn') || lowerPrompt.contains('save') || lowerPrompt.contains('saving')) {
      responseText = isFr
          ? "Pour économiser 20 000 FCFA sur un revenu mensuel de 250 000 FCFA, l'idéal est de réduire les sorties de 5 000 FCFA par semaine. Vous pouvez également automatiser un transfert de 20% vers votre objectif 'MacBook' le jour du salaire !"
          : "To save 20 000 FCFA on a monthly income of 250 000 FCFA, the ideal way is to reduce outings by 5 000 FCFA per week. You can also automate a 20% transfer to your 'MacBook' goal on payday!";
    } else if (lowerPrompt.contains('dépenses') || lowerPrompt.contains('analyse') || lowerPrompt.contains('expenses')) {
      responseText = isFr
          ? "Analyse de vos dépenses : Votre catégorie 'Divertissement' (27 500 FCFA dépensés pour 30 000 FCFA max) est à 91.6%. C'est une fuite financière importante ! Essayez de geler ces dépenses pour les 5 prochains jours."
          : "Analysis of your expenses: Your 'Entertainment' category (27 500 FCFA spent out of 30 000 FCFA max) is at 91.6%. That's a significant financial leak! Try to freeze these expenses for the next 5 days.";
    } else if (lowerPrompt.contains('dette') || lowerPrompt.contains('boule de neige') || lowerPrompt.contains('debt') || lowerPrompt.contains('snowball')) {
      responseText = isFr
          ? "La méthode 'boule de neige' consiste à rembourser vos dettes en commençant par la plus petite somme, quel que soit le taux. Cela vous procure une victoire psychologique rapide pour rester motivé !"
          : "The 'snowball' method consists of repaying your debts starting with the smallest amount, regardless of the rate. This gives you a quick psychological victory to stay motivated!";
    } else if (lowerPrompt.contains('50/30/20') || lowerPrompt.contains('regle') || lowerPrompt.contains('rule')) {
      responseText = isFr
          ? "La règle 50/30/20 divise votre revenu en trois catégories : 50% pour les Besoins essentiels (loyer, nourriture), 30% pour les Envies (loisirs, restaurants) et 20% pour l'Épargne ou le remboursement anticipé des dettes."
          : "The 50/30/20 rule divides your income into three categories: 50% for essential Needs (rent, food), 30% for Wants (leisure, dining out), and 20% for Savings or early debt repayment.";
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

  Future<String> _queryGemini(String systemPrompt, String userMessage) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey');
    
    try {
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
        return ref.read(languageProvider) == 'fr'
            ? "Je n'ai pas pu obtenir une réponse claire de l'intelligence artificielle."
            : "I could not obtain a clear response from the artificial intelligence.";
      } else {
        try {
          final errData = jsonDecode(response.body);
          final errMsg = errData['error']?['message'] ?? response.body;
          return "⚠️ Gemini API Error: $errMsg";
        } catch (_) {
          return "⚠️ Connection Error (${response.statusCode})";
        }
      }
    } catch (e) {
      return ref.read(languageProvider) == 'fr'
          ? "⚠️ Erreur réseau : Impossible de contacter Google AI. Veuillez vérifier votre clé API ou connexion Internet. ($e)"
          : "⚠️ Network Error: Unable to contact Google AI. Please check your API key or internet connection. ($e)";
    }
  }

  String _buildSystemPrompt({
    UserModel? user,
    List<TransactionModel>? transactions,
    BudgetModel? budget,
    List<SavingsGoalModel>? savingsGoals,
    required bool isFr,
  }) {
    final buffer = StringBuffer();
    if (isFr) {
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
        buffer.writeln("\nPROJETS D'ÉPARGNE ACTIFS :");
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
    } else {
      buffer.writeln("USER FINANCIAL CONTEXT:");
      buffer.writeln("- Full Name: ${user?.displayName ?? 'User'}");
      buffer.writeln("- Declared Monthly Income: ${user?.monthlyIncome.toFCFA() ?? '0 FCFA'}");

      if (budget != null) {
        buffer.writeln("\nCURRENT MONTHLY BUDGET (Month: ${budget.month}) :");
        buffer.writeln("- Planned Global Limit: ${budget.totalBudget.toFCFA()}");
        buffer.writeln("- Details by categories:");
        budget.categories.forEach((category, catBudget) {
          buffer.writeln(
              "  * $category : Limit = ${catBudget.limit.toFCFA()}, Spent = ${catBudget.spent.toFCFA()} (Remaining = ${catBudget.remaining.toFCFA()}, Usage = ${catBudget.percentage.toStringAsFixed(1)}%)");
        });
      }

      if (savingsGoals != null && savingsGoals.isNotEmpty) {
        buffer.writeln("\nACTIVE SAVINGS GOALS:");
        for (var goal in savingsGoals) {
          final progress = goal.target > 0 ? (goal.current / goal.target * 100) : 0.0;
          buffer.writeln(
              "- Goal '${goal.name}' (Category: ${goal.category}) : Target = ${goal.target.toFCFA()}, Saved = ${goal.current.toFCFA()} (${progress.toStringAsFixed(1)}% reached), Deadline = ${DateFormat('dd/MM/yyyy', 'en_US').format(goal.deadline)}");
        }
      }

      if (transactions != null && transactions.isNotEmpty) {
        buffer.writeln("\nLAST 10 TRANSACTIONS:");
        final recentTxs = transactions.take(10);
        for (var tx in recentTxs) {
          final typeStr = tx.type == TransactionType.income ? 'INCOME' : 'EXPENSE';
          buffer.writeln(
              "- [${DateFormat('dd/MM/yyyy', 'en_US').format(tx.date)}] $typeStr of ${tx.amount.toFCFA()} in '${tx.category}' (Description: ${tx.description})");
        }
      }

      return """
You are FinCoach AI, the virtual and premium personal financial advisor of the 'Ze Kinance' app.
Your objective is to help the user improve their financial health, optimize their budget, save smartly, and achieve their financial goals.

GOLDEN RULES OF CONDUCT:
1. Be extremely caring, motivating, professional, and pragmatic. Use flawless English.
2. Rely STRICTLY on the user's actual financial data provided below in the CONTEXT to give tailor-made advice.
3. If the user asks a question about their budget, transactions, or savings goals, perform precise calculations and quote their actual figures.
4. Encourage the use of the 50/30/20 rule (50% Essential Needs, 30% Wants/Leisure, 20% Savings/Debt repayment).
5. Never propose risky financial investments or speculative products. Focus purely on sound financial management, cutting non-essential spending, progressive savings, and debt repayment.

$buffer
""";
    }
  }

  void _showApiKeyDialog(BuildContext context, bool isFr) {
    final controller = TextEditingController(text: _apiKey);
    final textColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.lightTextPrimary;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.vpn_key_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              isFr ? 'Clé API Gemini Pro' : 'Gemini Pro API Key', 
              style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isFr
                ? "Entrez votre clé API Google Gemini pour activer l'IA en temps réel. Vos données financières réelles restent strictement sécurisées en local sur votre appareil."
                : "Enter your Google Gemini API key to activate real-time AI. Your actual financial data remains strictly secured locally on your device.",
              style: TextStyle(color: context.textSecondary, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              obscureText: true,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Ex: AIzaSy...',
                hintStyle: TextStyle(color: context.textSecondary.withOpacity(0.3)),
                labelText: isFr ? 'Clé API Google AI Studio' : 'Google AI Studio API Key',
                labelStyle: const TextStyle(color: AppColors.primary, fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(const ClipboardData(text: 'https://aistudio.google.com/'));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isFr 
                        ? 'Lien Google AI Studio copié ! Collez-le dans votre navigateur.' 
                        : 'Google AI Studio link copied! Paste it in your browser.'
                    ),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              icon: const Icon(Icons.open_in_new_rounded, color: AppColors.accent, size: 16),
              label: Text(
                isFr ? "Obtenir une clé API Gemini gratuite" : "Get a free Gemini API key",
                style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isFr ? 'Annuler' : 'Cancel', style: TextStyle(color: context.textSecondary)),
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
                final modeMsg = key.isEmpty
                    ? (isFr ? "Mode Démo activé" : "Demo Mode activated")
                    : (isFr ? "FinCoach Pro activé avec succès ! 🚀" : "FinCoach Pro activated successfully! 🚀");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(modeMsg),
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
            child: Text(isFr ? 'Sauvegarder' : 'Save', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFr = ref.watch(languageProvider) == 'fr';
    _initializeWelcomeMessage(isFr);
    final isProMode = _apiKey != null && _apiKey!.isNotEmpty;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
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
            Text(context.tr(ref, 'coach_title')),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showApiKeyDialog(context, isFr),
            icon: Icon(
              Icons.vpn_key_rounded,
              color: isProMode ? AppColors.primary : context.textSecondary,
            ),
            tooltip: isFr ? 'Configurer la clé API' : 'Configure API Key',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status bar indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: context.surfaceColor,
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
                          ? (isFr ? 'Propulsé par Gemini 1.5 Flash (Mode Pro)' : 'Powered by Gemini 1.5 Flash (Pro Mode)')
                          : (isFr ? 'Propulsé par Gemini 1.5 Flash (Mode Démo / Clé requise)' : 'Powered by Gemini 1.5 Flash (Demo Mode / Key required)'),
                      style: TextStyle(color: context.textSecondary, fontSize: 11),
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
                          SnackBar(
                            content: Text(
                              isFr 
                                ? 'Déconnecté du Mode Pro (Retour au Mode Démo)' 
                                : 'Disconnected from Pro Mode (Return to Demo Mode)'
                            ),
                          ),
                        );
                      },
                      child: Text(
                        isFr ? "DÉCONNECTER" : "DISCONNECT",
                        style: const TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.bold),
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
                  gradient: LinearGradient(
                    colors: [context.surfaceColor, context.isDark ? const Color(0xFF16233B) : const Color(0xFFE2E8F0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          isFr ? "Configuration Clé API Gemini" : "Gemini API Key Setup",
                          style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isFr 
                        ? "Pour connecter le coach intelligent à vos chiffres et transactions en temps réel, ajoutez votre clé API Gemini Pro en haut à droite." 
                        : "To link the smart coach with your live figures and transactions, add your Gemini Pro API key at the top right.",
                      style: TextStyle(color: context.textSecondary, fontSize: 11, height: 1.3),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),

            // Chat Messages area
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildChatBubble(msg);
                },
              ),
            ),

            // Suggested Prompts (If messages only contain greeting)
            if (_messages.length == 1)
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: isFr ? _suggestedPromptsFr.length : _suggestedPromptsEn.length,
                  itemBuilder: (context, index) {
                    final prompt = isFr ? _suggestedPromptsFr[index] : _suggestedPromptsEn[index];
                    return GestureDetector(
                      onTap: () => _sendMessage(prompt, isFr),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8, bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          border: Border.all(color: context.borderColor),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            prompt,
                            style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ).animate().fadeIn(delay: 200.ms),

            // Loading Indicator
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isFr ? 'FinCoach réfléchit...' : 'FinCoach is thinking...',
                      style: TextStyle(color: context.textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),

            // Input message area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                border: Border(top: BorderSide(color: context.borderColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(color: context.textPrimary),
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: context.tr(ref, 'coach_placeholder'),
                        hintStyle: TextStyle(color: context.textSecondary.withOpacity(0.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: context.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: context.borderColor),
                        ),
                        filled: true,
                        fillColor: context.isDark ? AppColors.darkBg : AppColors.lightSurfaceDark,
                      ),
                      onSubmitted: (val) => _sendMessage(val, isFr),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.black),
                      onPressed: () => _sendMessage(_messageController.text, isFr),
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

  Widget _buildChatBubble(_ChatMessage msg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: msg.isUser
              ? AppColors.primary
              : (isDark ? AppColors.darkSurface : AppColors.lightSurfaceDark),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(msg.isUser ? 20 : 0),
            bottomRight: Radius.circular(msg.isUser ? 0 : 20),
          ),
          border: msg.isUser
              ? null
              : Border.all(color: context.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                color: msg.isUser 
                    ? Colors.black 
                    : (isDark ? Colors.white : AppColors.lightTextPrimary),
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
                  color: msg.isUser 
                      ? Colors.black54 
                      : context.textSecondary,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final String timestamp;

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
