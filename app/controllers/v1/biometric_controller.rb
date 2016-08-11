# encoding: utf-8
class V1::BiometricController < V1::BaseController

  def send_biometric
    student_api_code = params[:IdAluno]
    biometric = params[:Biometria]
    biometric_type = params[:TipoBiometria]

    student_biometric = StudentBiometric.find_or_initialize_by(
      student: Student.find_by(api_code: student_api_code),
      biometric_type: biometric_type
    )
    student_biometric.biometric = biometric

    if student_biometric.save
      code = 1
      msg = "OK"
    else
      code = 2
      msg = student_biometric.errors.full_messages.join(", ")
    end

    render json: {
      "Codigo" => code,
      "Mensagem" => msg
    }
  end

  def request_biometric
    api_students = fetch_students_by_api_code params[:IdUnidade]

    result = Student.joins(:student_biometrics)
              .where(Student.arel_table[:api_code].in(api_students.map{|a| a["aluno_id"] }))
              .where(StudentBiometric.arel_table[:biometric_type].eq(params[:TipoBiometria]))
              .pluck("students.api_code, student_biometrics.biometric")

    render json: {
      "Dados" => {
        "Lista" => result.map{|api_code, biometric| { "IdAluno" => api_code.to_i, "Biometria" => biometric } }
      },"Status" => {
        "Codigo" => 1,
        "Mensagem" => "OK"
      }
    }
  end

  protected

  def fetch_students_by_api_code api_code
    api = IeducarApi::Students.new(IeducarApiConfiguration.current.to_api)
    api.fetch_registereds(
      {
        unity_api_code: api_code,
        date: Date.today,
        year: Date.today.year
      }
    )["alunos"].uniq
  end
end