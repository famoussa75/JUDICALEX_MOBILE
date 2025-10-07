// role.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../db/base_sqlite.dart';
import '../../widget/bottom_navigation_bar.dart';
import '../../widget/drawer.dart';
import '../../widget/user_provider.dart';
import '../API/api.role.dart';


class Role extends StatefulWidget {
  const Role({super.key});
  @override
  State<Role> createState() => _RoleState();
}

class _RoleState extends State<Role> {
  bool isLoggedIn = false;
  Map<String, dynamic>? roleDetails;
  List roles = [];
  List filteredRole = [];
  Map<int, String> juridictionMap = {};
  int totalPages = 0;
  int currentPage = 1;
  List<dynamic> filteredByRoleDates = [];
  ScrollController scrollController = ScrollController();
  String searchPresident = '';
  bool isLoading = true;
  bool isLoadingMore = false;
  final bool _isExpanded = false;
  bool _showYearsContainer = false;
  String _currentTitle = "Années";
  DateTime? selectedDate1;
  DateTime? selectedDate2;
  DateTime? selectedUniqueDate;
  String? selectedYear;
  String? _selectedYear;
  List<dynamic> _allRoles = [];
  bool isSearching = false;
  bool isFiltering = false;
  bool isSearchActive = false;
  bool isExpanded = false;
  Map<int, bool> expandedStates = {};
  bool _isSelected = false;
  int? selectedIndex;

  final RoleApi _roleApi = RoleApi(); // Instance de l'API

  @override
  void initState() {
    super.initState();
    fetchAllRolesWithQuery('');
    fetchPosts(isInitialLoad: true);
    scrollController.addListener(() {
      if (scrollController.position.pixels == scrollController.position.maxScrollExtent && !isLoadingMore) {
        _loadNextPage();
      }
    });
  }

  void _showLogin() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Connexion requise"),
            content: const Text("Veuillez vous connecter pour accéder à cette fonctionnalité."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Annuler"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, "/login");
                },
                child: const Text("Se connecter"),
              ),
            ],
          );
        }
    );
  }

  Future<void> fetchRoleDetails(String roleId) async {
    try {
      setState(() {
        isLoading = true;
      });

      final data = await _roleApi.fetchRoleDetails(roleId);

      setState(() {
        roleDetails = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showError("Erreur lors du chargement des détails du rôle");
    }
  }

  Future<void> fetchAllRolesWithQuery(String query) async {
    try {
      setState(() {
        isSearching = true;
      });

      final roles = await _roleApi.fetchAllRolesWithQuery(query);

      setState(() {
        _allRoles = roles;
        filteredRole = _allRoles;
        isSearching = false;
      });
    } catch (e) {
      setState(() {
        isSearching = false;
      });
      _showError(e.toString());
    }
  }

  Future<void> _filterRoles(String query, {bool filterByPresidentOnly = false}) async {
    setState(() {
      isSearchActive = query.isNotEmpty;
      isSearching = true;
      isFiltering = isSearchActive;
    });

    if (query.isEmpty && selectedDate1 == null && selectedDate2 == null && selectedUniqueDate == null) {
      setState(() {
        filteredRole = _allRoles;
        isSearchActive = false;
        isSearching = false;
        isFiltering = false;
      });
      return;
    }

    List<dynamic> searchResults = _allRoles.where((role) {
      final section = (role['section']?.toLowerCase() ?? '');
      final president = (role['president']?.toLowerCase() ?? '');
      final dateEnreg = (role['dateEnreg'] ?? '');
      final searchLower = query.toLowerCase();
      bool matchesText = section.contains(searchLower) ||
          president.contains(searchLower) ||
          dateEnreg.contains(searchLower);
      if (filterByPresidentOnly) {
        matchesText = president.contains(searchLower);
      }

      bool matchesDate = true;
      if (selectedDate1 != null || selectedDate2 != null) {
        if (role.containsKey('dateEnreg') && role['dateEnreg'].isNotEmpty) {
          try {
            final DateTime affaireDate = DateTime.parse(role['dateEnreg']);
            if (selectedDate1 != null && selectedDate2 != null) {
              matchesDate = (affaireDate.isAfter(selectedDate1!) && affaireDate.isBefore(selectedDate2!)) ||
                  affaireDate.isAtSameMomentAs(selectedDate1!) || affaireDate.isAtSameMomentAs(selectedDate2!);
            } else if (selectedDate1 != null) {
              matchesDate = affaireDate.isAfter(selectedDate1!) || affaireDate.isAtSameMomentAs(selectedDate1!);
            } else if (selectedDate2 != null) {
              matchesDate = affaireDate.isBefore(selectedDate2!) || affaireDate.isAtSameMomentAs(selectedDate2!);
            }
          } catch (e) {
            matchesDate = false;
          }
        } else {
          matchesDate = false;
        }
      }

      bool matchesUniqueDate = true;
      if (selectedUniqueDate != null) {
        if (role.containsKey('dateEnreg') && role['dateEnreg'].isNotEmpty) {
          try {
            final DateTime affaireDate = DateTime.parse(role['dateEnreg']);
            matchesUniqueDate = affaireDate.isAtSameMomentAs(selectedUniqueDate!);
          } catch (e) {
            matchesUniqueDate = false;
          }
        } else {
          matchesUniqueDate = false;
        }
      }
      return matchesText && matchesDate && matchesUniqueDate;
    }).toList();

    setState(() {
      filteredByRoleDates = searchResults;
      filteredRole = searchResults;
      isLoading = false;
      isSearching = false;
      isFiltering = false;
    });
  }

  Future<void> _selectDate(BuildContext context, int dateField) async {
    setState(() {
      isLoading = true;
    });

    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );

      if (picked != null) {
        setState(() {
          if (dateField == 1) {
            selectedDate1 = picked;
          } else if (dateField == 2) {
            selectedDate2 = picked;
          } else if (dateField == 3) {
            selectedUniqueDate = picked;
          }
        });

        await _filterRoles('');
      }
    } catch (e) {
      _showError("Erreur lors de la sélection de la date");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _filterByPresident(String query) async {
    setState(() {
      isSearchActive = query.isNotEmpty;
      isSearching = true;
      isFiltering = isSearchActive;
    });

    if (query.isEmpty) {
      setState(() {
        filteredRole = _allRoles;
        isSearchActive = false;
        isSearching = false;
        isFiltering = false;
      });
      return;
    }

    List<dynamic> searchResults = _allRoles.where((role) {
      final president = (role['president']?.toLowerCase() ?? '');
      final searchLower = query.toLowerCase();
      bool matchesText = president.contains(searchLower);
      return matchesText;
    }).toList();

    setState(() {
      filteredRole = searchResults;
      isLoading = false;
      isSearching = false;
      isFiltering = false;
    });
  }

  void _filterByYear(String year, {bool rest = false}) {
    setState(() {
      if (rest) {
        _selectedYear = null;
        filteredRole = _allRoles;
        _currentTitle = "Années";
      } else {
        _selectedYear = year;
        filteredRole = _allRoles.where((role) {
          final dateEnreg = role['dateEnreg'] ?? '';
          return dateEnreg.startsWith(year);
        }).toList();
      }
    });
  }

  void resetFilter() {
    setState(() {
      filteredRole = roles;
    });
  }

  Future<void> fetchPosts({bool isInitialLoad = false}) async {
    if (isSearchActive) {
      setState(() {
        isLoadingMore = false;
      });
      return;
    }

    try {
      setState(() {
        if (isInitialLoad) isLoading = true;
        else isLoadingMore = true;
      });

      final result = await _roleApi.fetchRoles(page: currentPage);

      if (mounted) {
        setState(() {
          if (isInitialLoad) {
            roles = result['roles'];
          } else {
            roles.addAll(result['roles']);
          }
          totalPages = result['totalPages'];

          if (!isSearchActive) {
            filteredRole = roles;
          }
          isLoading = false;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          isLoadingMore = false;
        });
        _showError(e.toString());
      }
    }
  }

  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "";
    try {
      DateTime date = DateTime.parse(dateStr);
      return DateFormat("dd/MM/yyyy").format(date);
    } catch (e) {
      return dateStr;
    }
  }

  void _showConnectionErrorWidget() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Connexion Internet'),
          content: const Text('Pas de connexion Internet. Veuillez vérifier votre réseau.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _refreshPage() async {
    setState(() {
      isLoading = true;
    });
    await fetchPosts();
    setState(() {
      isLoading = false;
    });
  }

  void _loadNextPage() {
    if (currentPage >= totalPages || isLoadingMore) {
      setState(() {
        isLoadingMore = false;
      });
    } else {
      setState(() {
        currentPage++;
        isLoadingMore = true;
      });
      fetchPosts();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final user = Provider.of<UserProvider>(context).currentUser;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: const Color(0xFF1e293b),
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          automaticallyImplyLeading: true,
          leadingWidth: 140,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Image.asset(
              "images/judicalex-blanc.png",
              height: 80,
            ),
          ),
          title: const SizedBox.shrink(),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () {
                Navigator.pushNamed(context, "/NotificationPage");
              },
            ),
          ],
        ),
      ),
      drawer: const MyDrawer(),
      body: RefreshIndicator(
        onRefresh: _refreshPage,
        child: Column(
          children: [
            if (!isExpanded)
              Padding(
                padding: const EdgeInsets.all(9.0),
                child: TextField(
                  onChanged: (value) => _filterRoles(value),
                  decoration: InputDecoration(
                    hintText: "Rechercher ",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isExpanded = !isExpanded;
                        if (!isExpanded) {
                          filteredRole = roles;
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isExpanded ? Icons.filter_alt : Icons.filter_alt_off,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isExpanded ? 'Masquer les filtres' : 'Affiner la recherche',
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (!isExpanded)
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showYearsContainer = !_showYearsContainer;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_currentTitle),
                          const SizedBox(width: 8),
                          Icon(
                            _showYearsContainer
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (_showYearsContainer)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30.0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: MediaQuery.of(context).size.width * 0.36,
                          height: 130,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black54.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 5,
                                offset: const Offset(0, 9),
                              ),
                            ],
                          ),
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Column(
                                children: (() {
                                  Set<String> uniqueYears = {};
                                  for (var role in _allRoles) {
                                    final year = role['dateEnreg']?.split('-')[0] ?? '';
                                    if (year.isNotEmpty) {
                                      uniqueYears.add(year);
                                    }
                                  }
                                  List<String> sortedYears = uniqueYears.toList()..sort();
                                  sortedYears.insert(0, "----");

                                  return sortedYears.isNotEmpty
                                      ? sortedYears.map((year) {
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (year == "----") {
                                            _selectedYear = null;
                                            _currentTitle = "Années";
                                            _showYearsContainer = false;
                                            resetFilter();
                                          } else {
                                            _selectedYear = year;
                                            _currentTitle = year;
                                            _showYearsContainer = false;
                                            _filterByYear(year);
                                          }
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            if (_selectedYear == year)
                                              const Icon(
                                                Icons.check_circle,
                                                color: Colors.green,
                                                size: 18,
                                              ),
                                            const SizedBox(width: 10),
                                            Text(
                                              year == "----" ? "Tous" : year,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: _selectedYear == year
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                                color: _selectedYear == year
                                                    ? Colors.green
                                                    : Colors.blue,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList()
                                      : [
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8.0),
                                      child: Text(
                                        'Aucune donnée',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueGrey,
                                        ),
                                      ),
                                    ),
                                  ];
                                })(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            if (isExpanded)
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  color: Colors.grey[200],
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedDate1 = null;
                              selectedDate2 = null;
                              selectedUniqueDate = null;
                              filteredRole = roles;
                            });
                          },
                          child: const Row(
                            children: [Text("Réinitialiser les champs")],
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: 340,
                          height: 50,
                          child: TextFormField(
                            onChanged: (value) {
                              setState(() {
                                searchPresident = value;
                                _filterByPresident(value);
                              });
                            },
                            decoration: InputDecoration(
                              hintText: "Rechercher par président",
                              prefixIcon: const Icon(Icons.search, color: Colors.blue),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: 340,
                          height: 50,
                          child: GestureDetector(
                            onTap: () => _selectDate(context, 3),
                            child: AbsorbPointer(
                              child: Stack(
                                children: [
                                  TextFormField(
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      hintText: selectedUniqueDate != null
                                          ? "${selectedUniqueDate!.day}/${selectedUniqueDate!.month}/${selectedUniqueDate!.year}"
                                          : "Veuillez sélectionner une date",
                                      prefixIcon: const Icon(Icons.calendar_today, color: Colors.blue),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                  if (isLoading)
                                    const Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16.0),
                            color: Colors.grey[200],
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Du"),
                                    Flexible(
                                      child: GestureDetector(
                                        onTap: () => _selectDate(context, 1),
                                        child: AbsorbPointer(
                                          child: TextFormField(
                                            readOnly: true,
                                            decoration: InputDecoration(
                                              hintText: selectedDate1 != null
                                                  ? "${selectedDate1!.day}/${selectedDate1!.month}/${selectedDate1!.year}"
                                                  : "Date",
                                              prefixIcon: const Icon(Icons.calendar_today, color: Colors.blue),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Text("Au"),
                                    Flexible(
                                      child: GestureDetector(
                                        onTap: () => _selectDate(context, 2),
                                        child: AbsorbPointer(
                                          child: TextFormField(
                                            readOnly: true,
                                            decoration: InputDecoration(
                                              hintText: selectedDate2 != null
                                                  ? "${selectedDate2!.day}/${selectedDate2!.month}/${selectedDate2!.year}"
                                                  : "Date",
                                              prefixIcon: const Icon(Icons.calendar_today, color: Colors.blue),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(8.0),
                itemCount: filteredRole.length + (isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == filteredRole.length) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final role = filteredRole[index];
                  final bool isSelected = selectedIndex == index;

                  return Card(
                    color: isSelected ? Colors.orangeAccent : Colors.white12,
                    child: InkWell(
                      onTap: () async {
                        setState(() {
                          selectedIndex = index;
                        });

                        if (user == null) {
                          _showLogin();
                        } else {
                          final roleId = role['id'].toString();
                          if (roleId.isNotEmpty) {
                            try {
                              await fetchRoleDetails(roleId);
                              if (roleDetails != null) {
                                await Navigator.pushNamed(
                                  context,
                                  "/Role_Details",
                                  arguments: roleId,
                                );
                                setState(() {
                                  selectedIndex = null;
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Les détails du rôle ne sont pas disponibles pour le moment.')),
                                );
                              }
                            } catch (error) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Une erreur s\'est produite lors de la récupération des informations.')),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ID de rôle introuvable.')),
                            );
                          }
                        }
                      },
                      child: Padding(
                        padding: EdgeInsets.all(screenWidth > 600 ? 16.0 : 8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.balance_sharp, size: 50, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${role['juridiction_name'] ?? 'inconnue'} - ${formatDate(role['dateEnreg'] ?? '')} - ${formatDate(role['typeAudience'] ?? '')}',
                                    style: TextStyle(
                                      fontSize: screenWidth > 600 ? 12 : 10,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1e293b),
                                    ),
                                    softWrap: true,
                                  ),
                                  SizedBox(height: screenWidth > 600 ? 10 : 4),
                                  Text(
                                    "Président(e): ${role['president'] ?? ''}",
                                    style: TextStyle(
                                      fontSize: screenWidth > 600 ? 12 : 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                  Text(
                                    role['section'] ?? '',
                                    style: TextStyle(
                                      fontSize: screenWidth > 600 ? 12 : 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (screenWidth > 400)
                              Padding(
                                padding: EdgeInsets.only(left: screenWidth > 600 ? 16 : 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.black : Colors.orange,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${role['total_affaire'] ?? 'Inconnu'} Affaires',
                                    style: TextStyle(
                                      fontSize: screenWidth > 600 ? 13 : 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: const CustomNavigator(currentIndex: 1),
    );
  }
}