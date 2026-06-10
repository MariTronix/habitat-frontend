import 'package:flutter/material.dart';

enum UserRole { master, coordenador, estagiario }

enum CaseStatus { triagem, documentacao, processo, finalizado }

enum TipoAtendimento { judicial, conciliacao }

extension UserRoleExtension on UserRole {
  String get label {
    switch (this) {
      case UserRole.master:
        return 'Administrador';
      case UserRole.coordenador:
        return 'Coordenador(a)';
      case UserRole.estagiario:
        return 'Estagiário(a)';
    }
  }
}

extension CaseStatusExtension on CaseStatus {
  String get label {
    switch (this) {
      case CaseStatus.triagem:
        return 'Triagem';
      case CaseStatus.documentacao:
        return 'Documentação';
      case CaseStatus.processo:
        return 'Em Processo';
      case CaseStatus.finalizado:
        return 'Finalizado';
    }
  }

  Color get color {
    switch (this) {
      case CaseStatus.triagem:
        return const Color(0xFF8B95A5);
      case CaseStatus.documentacao:
        return const Color(0xFFF59E0B);
      case CaseStatus.processo:
        return const Color(0xFF3B82F6);
      case CaseStatus.finalizado:
        return const Color(0xFF22C55E);
    }
  }
}

extension TipoAtendimentoExtension on TipoAtendimento {
  String get label {
    switch (this) {
      case TipoAtendimento.judicial:
        return 'Judicial';
      case TipoAtendimento.conciliacao:
        return 'Conciliação';
    }
  }
}

class User {
  final String id;
  final String nome;
  final String email;
  final UserRole role;
  final bool ativo;
  final String senha;

  User({
    required this.id,
    required this.nome,
    required this.email,
    required this.role,
    required this.ativo,
    required this.senha,
  });
}

class Morador {
  final String nome;
  final String cpf;
  final String telefone;
  final String endereco;

  Morador({
    required this.nome,
    required this.cpf,
    required this.telefone,
    required this.endereco,
  });
}

class CaminhoJudicial {
  final String numeroProcesso;
  final String varaJudicial;
  final String dataEntrada;
  final String statusProcesso;

  CaminhoJudicial({
    required this.numeroProcesso,
    required this.varaJudicial,
    required this.dataEntrada,
    required this.statusProcesso,
  });
}

class Conciliacao {
  final String dadosOutraParte;
  final String dataAudiencia;
  final String local;
  final String resultado;

  Conciliacao({
    required this.dadosOutraParte,
    required this.dataAudiencia,
    required this.local,
    required this.resultado,
  });
}

class Anotacao {
  final String id;
  final String texto;
  final String autor;
  final String data;

  Anotacao({
    required this.id,
    required this.texto,
    required this.autor,
    required this.data,
  });
}

class Documento {
  final String id;
  final String nome;
  final String tipo;
  final String data;

  Documento({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.data,
  });
}

class TimelineEvent {
  final String id;
  final String descricao;
  final String data;
  final String autor;
  final String tipo;

  TimelineEvent({
    required this.id,
    required this.descricao,
    required this.data,
    required this.autor,
    required this.tipo,
  });
}

class Caso {
  final String id;
  final Morador morador;
  final String descricao;
  final TipoAtendimento tipo;
  CaseStatus status;
  String estagiarioId;
  String coordenadorId;
  final String dataCriacao;
  String dataAtualizacao;
  CaminhoJudicial? caminhoJudicial;
  Conciliacao? conciliacao;
  List<Anotacao> anotacoes;
  List<Documento> documentos;
  List<TimelineEvent> timeline;

  Caso({
    required this.id,
    required this.morador,
    required this.descricao,
    required this.tipo,
    required this.status,
    required this.estagiarioId,
    required this.coordenadorId,
    required this.dataCriacao,
    required this.dataAtualizacao,
    this.caminhoJudicial,
    this.conciliacao,
    List<Anotacao>? anotacoes,
    List<Documento>? documentos,
    List<TimelineEvent>? timeline,
  })  : anotacoes = anotacoes ?? [],
        documentos = documentos ?? [],
        timeline = timeline ?? [];
}
