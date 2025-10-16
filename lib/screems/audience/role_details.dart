// role_detail.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widget/user_provider.dart';
import '../API/api.role_details.dart';

class RolesDetail extends StatefulWidget {
  const RolesDetail({super.key});

  @override
  State<RolesDetail> createState() => RolesDetailState();
}

class RolesDetailState extends State<RolesDetail> {
  List<dynamic>? roleDetails;
  bool isLoading = true;
  String errorMessage = '';
  bool isLoadingMore = false;

  Map<String, dynamic> role = {};
  List<dynamic>? affaireSuivis;
  List<bool> isCheckedList = [];

  String? juridiction;
  String? roleId;
  String? detailRoleId;

  final RoleDetailApi _apiService = RoleDetailApi();

  @override
  void initState() {
    super.initState();
    loadFollowedAffairs();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final String roleId = ModalRoute.of(context)!.settings.arguments as String;
    fetchRoleDetails(roleId);
  }

  bool showButtons = false;
  int? selectedIndex;
  bool selectAll = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: const Color(0xFF1e293b),
          iconTheme: const IconThemeData(color: Colors.white),
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          automaticallyImplyLeading: true,
          title: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                "images/judicalex-blanc1.png",
                height: 32,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () {
                    Navigator.pushNamed(context, "/NotificationPage");
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(0),
              children: <Widget>[
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: role != null
                                ? Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        if (role['juridiction_name'] != null && role['juridiction_name']!.isNotEmpty)
                                          Text(
                                            '${role['juridiction_name']}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Colors.black54),
                                          ),
                                        if (role['section'] != null && role['section']!.isNotEmpty)
                                          Text(
                                            '${role['section']}',
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black54),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Expanded(
                                        flex: 1,
                                        child: Text(
                                          "Type Audience :",
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          role['typeAudience'] ?? 'N/A',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Expanded(
                                        flex: 1,
                                        child: Text(
                                          "Date :",
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          role['dateEnreg'] ?? 'N/A',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (role['juge'] != null && role['juge']!.isNotEmpty)
                                    Row(
                                      children: [
                                        const Expanded(
                                          flex: 1,
                                          child: Text(
                                            "Juge :",
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            role['juge']!,
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (role['president'] != null && role['president']!.isNotEmpty)
                                    Row(
                                      children: [
                                        const Expanded(
                                          flex: 1,
                                          child: Text(
                                            "Président :",
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            role['president']!,
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (role['greffier'] != null && role['greffier']!.isNotEmpty)
                                    Row(
                                      children: [
                                        const Expanded(
                                          flex: 1,
                                          child: Text(
                                            "Greffier :",
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            role['greffier']!,
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ) : const  Center(
                              child: Text('Chargement des détails...'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[400],
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        icon: const Icon(Icons.check, color: Colors.white, size: 16),
                        label: const Text(
                          "Sélectionner tout",
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          setState(() {
                            for (int i = 0; i < isCheckedList.length; i++) {
                              isCheckedList[i] = true;
                            }
                            selectAll = true;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[400],
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        icon: const Icon(Icons.close, color: Colors.white, size: 16),
                        label: const Text(
                          "Désélectionner",
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          setState(() {
                            for (int i = 0; i < isCheckedList.length; i++) {
                              isCheckedList[i] = false;
                            }
                            selectAll = false;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                roleDetails != null && roleDetails!.isNotEmpty
                    ? ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  itemCount: roleDetails!.length,
                  itemBuilder: (context, index) {
                    final item = roleDetails![index];
                    return buildDetailRow(item, index);
                  },
                )
                    : const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('Aucune information disponible pour le moment')),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
              child: SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isCheckedList.contains(true)
                            ? () async {
                          final userProvider = Provider.of<UserProvider>(context, listen: false);
            
                          List<String> idAffaires = [];
                          for (int i = 0; i < isCheckedList.length; i++) {
                            if (isCheckedList[i]) {
                              idAffaires.add(roleDetails?[i]['id']?.toString() ?? 'N/A');
                            }
                          }
            
                          if (idAffaires.isNotEmpty) {
                            String? jurisdiction = role['juridiction']?.toString();
                            String? roleId = role['id']?.toString();
                            String? userId = userProvider.currentUser?.id.toString();
            
                            if (jurisdiction != null && userId != null) {
                              bool success = await _suivreAffaire(
                                context,
                                idAffaires,
                                jurisdiction,
                                roleId,
                                userId,
                              );
                              if (success && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: Colors.white70,
                                    content: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.green),
                                        SizedBox(width: 10),
                                        Text(
                                          'Félicitation! Vous suivez désormais ces affaires.',
                                          style: TextStyle(color: Colors.black54, fontSize: 10),
                                        ),
                                      ],
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                await Future.delayed(const Duration(seconds: 2));
                                if (mounted && roleId != null) {
                                  setState(() {
                                    fetchRoleDetails(roleId);
                                  });
                                }
                              }
                            } else if (mounted) {
                              _showError("Aucune affaire ou juridiction disponible pour la sélection effectuée.");
                            }
                          }
                        } : null,
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text("Suivre"),
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                              if (states.contains(MaterialState.disabled)) {
                                return Colors.grey.shade400;
                              }
                              if (states.contains(MaterialState.pressed)) {
                                return Colors.green.shade700;
                              }
                              if (states.contains(MaterialState.hovered)) {
                                return Colors.green.shade600;
                              }
                              return Colors.green;
                            },
                          ),
                          foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                          overlayColor: MaterialStateProperty.all<Color>(Colors.white.withOpacity(0.1)),
                          padding: MaterialStateProperty.all<EdgeInsets>(
                            const EdgeInsets.symmetric(vertical: 14),
                          ),
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          textStyle: MaterialStateProperty.all<TextStyle>(
                            const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          elevation: MaterialStateProperty.resolveWith<double>(
                                (Set<MaterialState> states) {
                              if (states.contains(MaterialState.pressed)) return 2;
                              return 6;
                            },
                          ),
                        ),
                      ),
                    ),
            
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isCheckedList.contains(true)
                            ? () async {
                          final userProvider = Provider.of<UserProvider>(context, listen: false);
            
                          List<String> idAffaires = [];
                          for (int i = 0; i < isCheckedList.length; i++) {
                            if (isCheckedList[i]) {
                              idAffaires.add(roleDetails?[i]['id']?.toString() ?? 'N/A');
                            }
                          }
            
                          if (idAffaires.isNotEmpty) {
                            String? jurisdiction = role['juridiction']?.toString();
                            String? roleId = role['id']?.toString();
                            String? userId = userProvider.currentUser?.id.toString();
            
                            if (jurisdiction != null && userId != null) {
                              bool success = await _nePasSuivre(
                                context,
                                idAffaires,
                                jurisdiction,
                                roleId,
                                userId,
                              );
                              if (success && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: Colors.white70,
                                    content: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.close_sharp, color: Colors.red),
                                        SizedBox(width: 10),
                                        Text(
                                          'Vous ne suivez plus ces affaires.',
                                          style: TextStyle(color: Colors.black54, fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                                await Future.delayed(const Duration(seconds: 2));
                                if (mounted && roleId != null) {
                                  setState(() {
                                    fetchRoleDetails(roleId);
                                  });
                                }
                              }
                            } else if (mounted) {
                              _showError("Aucune affaire ou juridiction disponible pour la sélection effectuée.");
                            }
                          }
                        }
                            : null,
                        icon: const Icon(Icons.close, color: Colors.white),
                        label: const Text("Ne plus suivre"),
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                              if (states.contains(MaterialState.disabled)) {
                                return Colors.grey.shade400;
                              }
                              if (states.contains(MaterialState.pressed)) {
                                return Colors.red.shade700;
                              }
                              if (states.contains(MaterialState.hovered)) {
                                return Colors.red.shade600;
                              }
                              return Colors.red;
                            },
                          ),
                          foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                          overlayColor: MaterialStateProperty.all<Color>(
                              Colors.white.withOpacity(0.1)),
                          padding: MaterialStateProperty.all<EdgeInsets>(
                            const EdgeInsets.symmetric(vertical: 14),
                          ),
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          textStyle: MaterialStateProperty.all<TextStyle>(
                            const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          elevation: MaterialStateProperty.resolveWith<double>(
                                (Set<MaterialState> states) {
                              if (states.contains(MaterialState.pressed)) return 2;
                              return 6;
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  void suivre(int index) {
    setState(() {
      isCheckedList[index] = true;
    });
  }

  Widget buildDetailRow(Map<String, dynamic> item, int index) {
    String idAffaire = item['id']?.toString() ?? 'N/A';
    String numOrdre = item['numOrdre']?.toString() ?? 'N/A';
    String demandeurs = item['demandeurs'] ?? 'N/A';
    String defendeurs = item['defendeurs'] ?? 'N/A';
    String objet = item['objet'] ?? 'N/A';

    bool alreadyFollowed = affaireSuivis!.any((affaire) {
      String idSuivre = affaire['affaire']?.toString() ?? 'N/A';
      return idAffaire == idSuivre;
    });

    if (isCheckedList.length <= index) {
      isCheckedList.add(false);
    }

    final bool isSelected = selectedIndex == index || isCheckedList[index];

    return Card(
      color: isSelected ? const Color(0xFFDFB23D): Colors.white12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: InkWell(
          onTap: () {
            setState(() {
              selectedIndex = index;
            });
            _showAffaireDetailsDialog(idAffaire);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            'N°: $numOrdre',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            alreadyFollowed ? 'Déjà suivi' : '',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: alreadyFollowed ? Colors.green : Colors.red,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Checkbox(
                    value: isCheckedList[index],
                    activeColor: const Color(0xFFDFB23D) ,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    onChanged: (bool? value) {
                      setState(() {
                        isCheckedList[index] = value ?? false;
                        selectAll = !isCheckedList.contains(false);
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Demandeurs: $demandeurs', style: const TextStyle(fontSize: 11)),
              const SizedBox(height: 4),
              Text('Défendeurs: $defendeurs', style: const TextStyle(fontSize: 11)),
              const SizedBox(height: 4),
              Text('Objet: $objet', style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  // Méthodes API wrapper pour la vue
  Future<void> fetchRoleDetails(String roleId) async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final data = await _apiService.fetchRoleDetails(roleId);

      if (!mounted) return;
      setState(() {
        juridiction = data['juridiction'];
        this.roleId = roleId;
        role = data['role'];
        roleDetails = data['detailRole'];
        affaireSuivis = data['affaireSuivis'];
        isLoading = false;
        isCheckedList = List<bool>.filled(roleDetails!.length, false);
      });

     /// print("Détails du rôle : $roleDetails");
      ///print('ID du rôle: $roleId');
     /// print(data['affaireSuivis']);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<bool> _suivreAffaire(
      BuildContext context,
      List<String> idAffaires,
      String juridiction,
      String? roleId,
      String? userId
      ) async {
    try {
      return await _apiService.suivreAffaire(idAffaires, juridiction, userId);
    } catch (e) {
      _showError(e.toString());
      return false;
    }
  }

  Future<bool> _nePasSuivre(
      BuildContext context,
      List<String> idAffaires,
      String juridiction,
      String? roleId,
      String? userId
      ) async {
    try {
      return await _apiService.nePasSuivre(idAffaires, juridiction, userId);
    } catch (e) {
      _showError(e.toString());
      return false;
    }
  }

  Future<void> loadFollowedAffairs() async {
    try {
      final followedAffairs = await _apiService.loadFollowedAffairs();
      if (roleDetails != null) {
        isCheckedList = List<bool>.filled(roleDetails!.length, false);
        for (String id in followedAffairs) {
          int index = roleDetails?.indexWhere((element) => element['id'].toString() == id) ?? -1;
          if (index != -1) {
            isCheckedList[index] = true;
          }
        }
      }
      setState(() {});
    } catch (e) {
     /// print('Erreur lors du chargement des affaires suivies: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showAffaireDetailsDialog(String idAffaire) async {
    try {
      final data = await _apiService.fetchRoleDetailsDecision(idAffaire);
      final decisions = data['decisions'] ?? [];
      setState(() {
        selectedIndex = null;
      });
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: '',
        barrierColor: Colors.black.withOpacity(0.2),
        pageBuilder: (context, anim1, anim2) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Center(
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () async {
                            await Navigator.pushNamed(
                              context,
                              "/Decisions",
                              arguments: {
                                'id': idAffaire,
                                'role': role,
                              },
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "NUA : ${data['affaire']['numAffaire']}",
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text.rich(
                                TextSpan(
                                  style: const TextStyle(color: Colors.black),
                                  children: [
                                    const TextSpan(
                                      text: "Objet: ",
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    TextSpan(
                                      text: data['affaire']['objet'] ?? 'Objet non précisé',
                                      style: const TextStyle(
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (decisions.isNotEmpty)
                        Expanded(
                          child: PageView.builder(
                            itemCount: decisions.length,
                            itemBuilder: (context, index) {
                              return _buildDecisionCard(decisions[index], index, decisions.length);
                            },
                          ),
                        )
                      else
                        const Center(child: Text("Aucune décision disponible.")),

                      const SizedBox(height: 10),
                      Center(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color:  Color(0xFFDFB23D) , width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          onPressed: () {
                            Navigator.of(context, rootNavigator: true).pop();
                          },
                          child: const Text(
                            "Retour",
                            style: TextStyle(color:  Color(0xFFDFB23D) ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors du chargement des détails")),
      );
    }
  }

  Widget _buildDecisionCard(Map<String, dynamic> decision, int index, int total) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (index > 0)
                  const Icon(Icons.arrow_left, color: Color(0xFFDFB23D) , size: 30),
                Text(
                  "Décision ${index + 1}/$total",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDFB23D) ,
                  ),
                ),
                if (index < total - 1)
                  const Icon(Icons.arrow_right, color:  Color(0xFFDFB23D) , size: 30),
              ],
            ),
            const Divider(),
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  const WidgetSpan(
                    child: Text(
                      "Type: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const WidgetSpan(child: SizedBox(width: 4)),
                  TextSpan(text: decision['typeDecision'] ?? 'Non spécifié'),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  const WidgetSpan(
                    child: Text(
                      "Date: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const WidgetSpan(child: SizedBox(width: 4)),
                  TextSpan(text: decision['dateDecision'] ?? 'Non précisé'),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  const WidgetSpan(
                    child: Text(
                      "Président: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const WidgetSpan(child: SizedBox(width: 4)),
                  TextSpan(text: role['president'] ?? 'Inconnu'),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  const WidgetSpan(
                    child: Text(
                      "Greffier: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const WidgetSpan(child: SizedBox(width: 4)),
                  TextSpan(text: role['greffier'] ?? 'Inconnu'),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  const WidgetSpan(
                    child: Text(
                      "Décision: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const WidgetSpan(child: SizedBox(width: 4)),
                  TextSpan(
                    text: decision['decision'] ?? 'Inconnu',
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  const WidgetSpan(
                    child: Text(
                      "Prochaine Audience: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const WidgetSpan(child: SizedBox(width: 4)),
                  TextSpan(text: decision['prochaineAudience'] ?? 'Non précisé'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}