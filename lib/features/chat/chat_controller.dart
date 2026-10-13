import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:foodpilot/data/providers.dart';
import 'package:foodpilot/data/repositories/menu_repository.dart';
import 'package:foodpilot/domain/chat_command.dart';
import 'package:foodpilot/domain/models.dart';
import 'package:foodpilot/features/analisis/ai_service.dart';

/// Satu gelembung di layar chat.
sealed class ChatBubble {
  const ChatBubble();
}

/// Kalimat yang diketik pemilik.
final class ChatUserText extends ChatBubble {
  const ChatUserText(this.text);

  final String text;
}

/// Kalimat biasa dari asisten: pertanyaan, penjelasan, atau pesan gagal.
final class ChatBotText extends ChatBubble {
  const ChatBotText(this.text, {this.isError = false});

  final String text;
  final bool isError;
}

/// Draf menu yang menunggu konfirmasi. Setelah disimpan, kartunya tetap
/// ada di riwayat tapi tombolnya hilang.
final class ChatDraft extends ChatBubble {
  const ChatDraft(this.draft, {this.saved = false});

  final ChatAddMenu draft;
  final bool saved;
}

class ChatState {
  const ChatState({this.bubbles = const <ChatBubble>[], this.busy = false});

  final List<ChatBubble> bubbles;
  final bool busy;

  ChatState copyWith({List<ChatBubble>? bubbles, bool? busy}) {
    return ChatState(
      bubbles: bubbles ?? this.bubbles,
      busy: busy ?? this.busy,
    );
  }
}

/// Batas tunggu sama dengan konsultan AI (CONTEXT.md bagian 6).
const Duration chatTimeout = Duration(seconds: 20);

class ChatController extends Notifier<ChatState> {
  @override
  ChatState build() => const ChatState();

  void _tambah(ChatBubble bubble) {
    state = state.copyWith(bubbles: <ChatBubble>[...state.bubbles, bubble]);
  }

  Future<void> kirim(String kalimat) async {
    final teks = kalimat.trim();
    if (teks.isEmpty || state.busy) return;

    _tambah(ChatUserText(teks));
    state = state.copyWith(busy: true);

    try {
      final service = ref.read(aiServiceProvider);
      final perintah = await service.chat(teks).timeout(chatTimeout);

      switch (perintah) {
        case ChatAddMenu():
          _tambah(ChatDraft(perintah));
        case ChatAsk(:final question):
          _tambah(ChatBotText(question));
        case ChatUnknown(:final message):
          _tambah(ChatBotText(message));
      }
    } on TimeoutException {
      _tambah(
        const ChatBotText(
          'Tidak ada balasan dalam 20 detik. Periksa koneksi, lalu coba lagi.',
          isError: true,
        ),
      );
    } on SocketException {
      _tambah(
        const ChatBotText(
          'Tidak bisa menghubungi server. Menu tetap bisa ditambah lewat '
          'tombol tambah di halaman Menu.',
          isError: true,
        ),
      );
    } on AiException catch (error) {
      _tambah(ChatBotText(error.message, isError: true));
    } catch (error) {
      _tambah(ChatBotText('Gagal memproses: $error', isError: true));
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  /// Menyimpan draf ke database.
  ///
  /// Bahan hasil chat disimpan dengan jumlah satu dan satuan porsi, karena
  /// pemilik menyebut harga bahan untuk satu porsi, bukan harga per gram.
  /// Hasil perhitungan HPP-nya sama.
  Future<void> simpan(ChatDraft bubble) async {
    if (state.busy) return;
    state = state.copyWith(busy: true);

    try {
      final business = await ref.read(businessProvider.future);
      if (business == null) {
        _tambah(
          const ChatBotText(
            'Data usaha belum ada. Isi dulu lewat Profil.',
            isError: true,
          ),
        );
        return;
      }

      final draft = bubble.draft;
      await ref
          .read(menuRepositoryProvider)
          .saveProduct(
            businessId: business.id,
            name: draft.name,
            sellPrice: draft.sellPrice,
            ingredients: <IngredientInput>[
              for (final item in draft.ingredients)
                IngredientInput(
                  name: item.name,
                  qty: 1,
                  unit: IngredientUnit.pcs,
                  unitPrice: item.price,
                ),
            ],
          );

      // Kartu yang sama ditandai tersimpan, supaya tombolnya hilang dan
      // pemilik tidak menyimpan dua kali.
      state = state.copyWith(
        bubbles: <ChatBubble>[
          for (final item in state.bubbles)
            if (identical(item, bubble)) ChatDraft(draft, saved: true) else item,
        ],
      );
      _tambah(ChatBotText('${draft.name} sudah masuk daftar menu.'));
    } catch (error) {
      _tambah(ChatBotText('Gagal menyimpan: $error', isError: true));
    } finally {
      state = state.copyWith(busy: false);
    }
  }
}

final chatControllerProvider = NotifierProvider<ChatController, ChatState>(
  ChatController.new,
);