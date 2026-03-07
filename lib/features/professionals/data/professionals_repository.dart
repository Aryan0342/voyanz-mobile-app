import 'package:voyanz/features/professionals/data/professionals_data_source.dart';
import 'package:voyanz/features/professionals/models/professional.dart';

class ProfessionalsRepository {
  final ProfessionalsDataSource _ds;

  ProfessionalsRepository(this._ds);

  Future<List<Professional>> getProfessionals() => _ds.getProfessionals();

  Future<ProfessionalDetail> getProfessionalInfos(String coId) =>
      _ds.getProfessionalInfos(coId);

  Future<List<dynamic>> getDisponibilities() => _ds.getDisponibilities();

  Future<void> createDisponibility(Map<String, dynamic> data) =>
      _ds.createDisponibility(data);
}
