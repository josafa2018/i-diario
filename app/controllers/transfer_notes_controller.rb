class TransferNotesController < ApplicationController
  before_action :require_current_teacher
  before_action :require_current_school_calendar
  has_scope :page, default: 1
  has_scope :per, default: 10

  def index
    @transfer_notes = apply_scopes(TransferNote).includes(:classroom, :discipline, :student)
                                                .by_teacher_id(current_teacher.id)
                                                .by_unity_id(current_user_unity.id)

    authorize @transfer_notes
  end

  def new
    @transfer_note = TransferNote.new(
      unity_id: current_user_unity.id
    )

    authorize @transfer_note
  end

  def create
    @transfer_note = TransferNote.new(resource_params)
    @transfer_note.teacher = current_teacher

    authorize @transfer_note

    if @transfer_note.save
      respond_with @transfer_note, location: transfer_notes_path
    else
      render :new
    end
  end

  def edit
    @transfer_note = TransferNote.find(params[:id]).localized
    authorize @transfer_note
  end

  def update
    @transfer_note = TransferNote.find(params[:id])
    @transfer_note.assign_attributes(resource_params)

    authorize @transfer_note

    if @transfer_note.save
      respond_with @transfer_note, location: transfer_notes_path
    else
      render :new
    end
  end

  def current_notes
    return unless params[:classroom_id] && params[:discipline_id] && params[:school_calendar_step_id] && params[:student_id] && params[:transfer_date]

    classroom = Classroom.find(params[:classroom_id])
    school_calendar_step = SchoolCalendarStep.find(params[:school_calendar_step_id])
    avaliations = Avaliation.by_classroom_id(params[:classroom_id])
                            .by_discipline_id(params[:discipline_id])
                            .by_teacher(current_teacher.id)
                            .by_test_date_between(school_calendar_step.start_at, params[:transfer_date])

    @daily_note_students = avaliations.map do |avaliation|
      daily_note = DailyNote.find_or_create_by!(
        classroom_id: classroom.id,
        unity_id: classroom.unity.id,
        discipline_id: params[:discipline_id],
        avaliation_id: avaliation.id
      )

      DailyNoteStudent.find_or_initialize_by(
        daily_note_id: daily_note.id,
        student_id: params[:student_id]
      )
    end
    render(json: @daily_note_students, include: { daily_notes: [:avaliation] })
  end

  def history
    @transfer_note = TransferNote.find(params[:id]).localized

    authorize @transfer_note

    respond_with @transfer_note
  end

  def destroy
    @transfer_note = TransferNote.find(params[:id])

    authorize @transfer_note

    @transfer_note.destroy

    respond_with @transfer_note, location: transfer_notes_path
  end

  private

  def unities
    @unities = [ @transfer_note.classroom.present? ? @transfer_note.classroom.unity : current_user_unity ]
  end
  helper_method :unities

  def classrooms
    @classrooms ||= Classroom.by_unity_and_teacher(
      current_user_unity.id,
      current_teacher.id
    )
    .ordered
  end
  helper_method :classrooms

  def disciplines
    @disciplines = []
  end
  helper_method :disciplines

  def students
    @students = (@transfer_note.student_id.present? ? [@transfer_note.student] : [])
  end
  helper_method :students

  def school_calendar_steps
    @school_calendar_steps ||= current_school_calendar.steps
  end
  helper_method :school_calendar_steps

  def resource_params
    params.require(:transfer_note).permit(
      :unity_id,
      :classroom_id,
      :discipline_id,
      :school_calendar_step_id,
      :transfer_date,
      :student_id,
      daily_note_students_attributes: [
        :id,
        :student_id,
        :daily_note_id,
        :note
      ]
    )
  end
end