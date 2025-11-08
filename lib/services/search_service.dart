import 'package:cloud_firestore/cloud_firestore.dart';

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> searchUsersByName(String query) async {
    if (query.trim().isEmpty) return [];

    final snap = await _firestore
        .collectionGroup('public')
        .where('name', isGreaterThanOrEqualTo: query.trim())
        .where('name', isLessThanOrEqualTo: '${query.trim()}\uf8ff')
        .limit(10)
        .get();

    return snap.docs.map((doc) {
      final data = doc.data();
      data['uid'] = doc.reference.parent.parent!.id;
      return data;
    }).toList();
  }
}