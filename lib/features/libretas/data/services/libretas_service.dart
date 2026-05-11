import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:a_core/features/libretas/data/models/libreta_model.dart';
import 'package:a_core/features/libretas/data/models/pagina_model.dart';
import 'package:a_core/features/libretas/domain/entities/libreta.dart';
import 'package:a_core/features/libretas/domain/entities/pagina.dart';

class LibretasService {
  final _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  CollectionReference _libretas(String uid) =>
      _db.collection('users').doc(uid).collection('libretas');

  CollectionReference _paginas(String uid) =>
      _db.collection('users').doc(uid).collection('paginas');

  // ── Libretas ──────────────────────────────────

  Future<Libreta> createLibreta({
    required String userId,
    required String titulo,
    String? descripcion,
    required String emoji,
    required String color,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final libreta = LibretaModel(
      id: id,
      userId: userId,
      titulo: titulo,
      descripcion: descripcion,
      emoji: emoji,
      color: color,
      paginasCount: 0,
      createdAt: now,
      updatedAt: now,
    );
    await _libretas(userId).doc(id).set(libreta.toFirestore());
    return libreta;
  }

  Future<void> updateLibreta(String userId, Libreta libreta) async {
    final model = LibretaModel.fromEntity(libreta);
    await _libretas(userId).doc(libreta.id).update({
      ...model.toFirestore(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteLibreta(String userId, String libretaId) async {
    // Borra todas las páginas de la libreta también
    final batch = _db.batch();
    final pags = await _paginas(userId).where('libretaId', isEqualTo: libretaId).get();
    for (final doc in pags.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_libretas(userId).doc(libretaId));
    await batch.commit();
  }

  Stream<List<Libreta>> watchLibretas(String userId) {
    return _libretas(userId).snapshots().map((s) {
      final list = s.docs
          .map((d) {
            try {
              return LibretaModel.fromFirestore(d);
            } catch (e) {
              debugPrint('Error parsing libreta ${d.id}: $e');
              return null;
            }
          })
          .whereType<LibretaModel>()
          .toList();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    });
  }

  // ── Páginas ───────────────────────────────────

  Future<Pagina> createPagina({
    required String userId,
    required String libretaId,
    required String titulo,
    String? parentId,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    // Cuenta páginas existentes para el orden
    final existing = await _paginas(
      userId,
    ).where('libretaId', isEqualTo: libretaId).where('parentId', isEqualTo: parentId).get();

    final pagina = PaginaModel(
      id: id,
      libretaId: libretaId,
      userId: userId,
      titulo: titulo,
      contenido: '',
      parentId: parentId,
      orden: existing.docs.length,
      createdAt: now,
      updatedAt: now,
    );

    final batch = _db.batch();
    batch.set(_paginas(userId).doc(id), pagina.toFirestore());

    // Si es sub-página, agrega su id al parent
    if (parentId != null) {
      batch.update(_paginas(userId).doc(parentId), {
        'subPaginasIds': FieldValue.arrayUnion([id]),
      });
    }

    // Incrementa contador en la libreta
    batch.update(_libretas(userId).doc(libretaId), {
      'paginasCount': FieldValue.increment(1),
      'updatedAt': Timestamp.fromDate(now),
    });

    await batch.commit();
    return pagina;
  }

  Future<void> savePagina(String userId, Pagina pagina) async {
    final model = PaginaModel.fromEntity(pagina);
    await _paginas(userId).doc(pagina.id).update({
      ...model.toFirestore(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
    // Actualiza updatedAt de la libreta
    await _libretas(
      userId,
    ).doc(pagina.libretaId).update({'updatedAt': Timestamp.fromDate(DateTime.now())});
  }

  Future<void> deletePagina(String userId, Pagina pagina) async {
    final batch = _db.batch();

    // Borra sub-páginas recursivamente
    await _deleteSubPaginas(userId, pagina.id, batch);

    // Quita su id del parent si tiene
    if (pagina.parentId != null) {
      batch.update(_paginas(userId).doc(pagina.parentId!), {
        'subPaginasIds': FieldValue.arrayRemove([pagina.id]),
      });
    }

    batch.delete(_paginas(userId).doc(pagina.id));

    // Decrementa contador
    batch.update(_libretas(userId).doc(pagina.libretaId), {
      'paginasCount': FieldValue.increment(-1),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    await batch.commit();
  }

  Future<void> _deleteSubPaginas(String userId, String paginaId, WriteBatch batch) async {
    final subs = await _paginas(userId).where('parentId', isEqualTo: paginaId).get();
    for (final doc in subs.docs) {
      await _deleteSubPaginas(userId, doc.id, batch);
      batch.delete(doc.reference);
    }
  }

  Future<void> renamePagina(String userId, String paginaId, String nuevoTitulo) async {
    await _paginas(userId).doc(paginaId).update({
      'titulo': nuevoTitulo,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Stream<List<Pagina>> watchPaginas(String userId, String libretaId) {
    return _paginas(userId).where('libretaId', isEqualTo: libretaId).snapshots().map((s) {
      final list = s.docs.map((d) => PaginaModel.fromFirestore(d)).toList();
      list.sort((a, b) => a.orden.compareTo(b.orden));
      return list;
    });
  }

  Future<Pagina?> getPagina(String userId, String paginaId) async {
    final doc = await _paginas(userId).doc(paginaId).get();
    if (!doc.exists) return null;
    return PaginaModel.fromFirestore(doc);
  }
}
