extends Node2D
@onready var topic_selector = get_node("/root/Node2D/TopicSelector")
@onready var start_menu = get_node("/root/Node2D/Background")
@onready var write_notes = get_node("/root/Node2D/WriteNotes")
@onready var revision = get_node("/root/Node2D/Revision")
@onready var back_button = get_node("/root/Node2D/BackButton")
@onready var error = get_node("/root/Node2D/Error")
@onready var topic_creator = get_node("/root/Node2D/TopicCreator")
@onready var topic_1 = get_node("/root/Node2D/TopicSelector/Topic1")
@onready var topic_2 = get_node("/root/Node2D/TopicSelector/Topic2")
@onready var topic_3 = get_node("/root/Node2D/TopicSelector/Topic3")
@onready var topic_4 = get_node("/root/Node2D/TopicSelector/Topic4")

var db = SQLite.new()
#Used to define the mode (Revision or Writing Notes)
var mode = ''
#Used to load corresponding Data for that subject, e.g. 
#Questions for Revision OR Writing Notes for that subject 
var topic = ''
var topic_selected 
#Used to return to the previous menu using the same back button node
var previous_menu
var current_menu

var answer_input
var user_answer
var user_has_submitted_answer
var stop_revision = false
var next_question = false
# _ready() runs on startup
func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir() +"/database")
	#Pathway for accessing the Database
	db.path = "user://database/flashcard.db"
	#Opens the Database
	db.open_db()
	db.query("CREATE TABLE IF NOT EXISTS \"Default\" (id INTEGER PRIMARY KEY AUTOINCREMENT, question TEXT, answer TEXT)")
	
	topic_selector.visible = false
	write_notes.visible = false
	topic_creator.visible = false
	revision.visible = false
	back_button.visible = false
	error.visible = false
		
	start_menu.visible = true

	

func revision_process():
	#Used to load back once you're in the revision part
	#Use a while loop to keep asking questions
	while stop_revision == false:
		topic_selector.visible = false
		current_menu = revision
		previous_menu = topic_selector
		back_button.visible = true
		revision.visible = true
		
		var answer_comparison = get_node("/root/Node2D/Revision/AnswerComparison")
		answer_comparison.visible = false
		var answer_panel = get_node("/root/Node2D/Revision/AnswerPanel")

		answer_panel.visible = true
		
		user_has_submitted_answer = false
		#Set the Question up]
		db.query("SELECT * FROM \"" + topic + "\" ORDER BY RANDOM() LIMIT 1")
		print(db.query_result)
		var random_question = db.query_result[0]["question"]
		var question_answer = db.query_result[0]["answer"]
		var question = get_node("/root/Node2D/Revision/QuestionPanel/Question")
		question.text = random_question
		
		while user_has_submitted_answer == false:
			await get_tree().process_frame
			
		#Once user has submitted answer, Show them the answer and theirs to compare
		next_question = false
		answer_panel.visible = false
		
		var user_answer_label = get_node("/root/Node2D/Revision/AnswerComparison/UserAnswer")
		var actual_answer = get_node("/root/Node2D/Revision/AnswerComparison/ActualAnswer")
		user_answer_label.text = user_answer
		actual_answer.text = question_answer
		
		answer_comparison.visible = true
		
		while next_question == false:
			await get_tree().process_frame
			
		
		
	
func write_notes_process():
	#Used to load back once you're in the write_notes part
	current_menu = write_notes
	previous_menu = topic_selector
	write_notes.visible = true
	#Needs to be done
	pass

func topic_selector_process():
	back_button.visible = true
	current_menu = topic_selector
	previous_menu = start_menu
	topic_selector.visible = true
	for i in range(0, 4):
		var button_hide = get_node("/root/Node2D/TopicSelector/Topic" + str(i + 1))
		button_hide.visible = false
		
	#Need to Load in buttons for each table in the database
	#Ask 'Hey, How many tables are in Flashcard.db?'
	db.query("SELECT name FROM sqlite_master WHERE type='table' AND name != 'sqlite_sequence' AND name != 'Default'")
	var number_of_tables = db.query_result.size()
	
	#Assign a button for each table
	for i in range(number_of_tables):
		var table_name = db.query_result[i]["name"]
		var button = get_node("/root/Node2D/TopicSelector/Topic" + str(i + 1))
		button.visible = true
		button.text = table_name
		
	topic_selected = false
	
	while topic_selected == false:
		await get_tree().process_frame
	

	

#Need to have 2 Modes
# - Revision
# - Write Notes

func _on_quit_pressed() -> void:
	#Quits the Game
	get_tree().quit()
	
func _on_write_notes_button_pressed() -> void:
	mode = 'Write Notes'
	start_menu.visible = false
	back_button.visible = true
	await topic_selector_process()
	topic_selector.visible = false
	write_notes_process()
	
func _on_revision_button_pressed() -> void:
	mode = 'Revision'
	back_button.visible = true
	start_menu.visible = false
	await topic_selector_process()
	revision_process()

func _on_back_button_pressed() -> void:
	current_menu.visible = false
	previous_menu.visible = true

	if previous_menu == topic_selector:
		await topic_selector_process()
		topic_selector.visible = false

		if mode == "Write Notes":
			write_notes_process()
		elif mode == "Revision":
			revision_process()
	else:
		back_button.visible = false
		
	if current_menu == revision:
		stop_revision = true
		

func _on_add_to_database_pressed() -> void:
	
	var question = get_node("/root/Node2D/WriteNotes/Question")
	var answer = get_node("/root/Node2D/WriteNotes/Answer")
	
	if question.text.is_empty() or answer.text.is_empty():
		error.visible = true
		error.text = "Error: Question or Answer is Empty!"
		await get_tree().create_timer(3.0).timeout
		error.visible = false
	else:
		#Add to the database
		var database_write = "INSERT INTO \"" + str(topic) + "\" (question, answer) VALUES (?, ?)"

		db.query_with_bindings(database_write, [question.text, answer.text])
		
		#Reseting so people don't spam the same question into the database
		question.text = ""
		answer.text = ""
		pass
		#Add to the Database
	pass # Replace with function body.


func _on_create_new_topic_pressed() -> void:
	topic_creator.visible = true
	
	pass # Replace with function body.


func _on_topic_creator_create_pressed() -> void:
	var topic_creator_input = get_node("/root/Node2D/TopicCreator/TopicCreatorInput")
	if topic_creator_input.text.is_empty():
		error.visible = true
		error.text = "Error: You Didn't input anything!"
		await get_tree().create_timer(3.0).timeout
		error.visible = false
	else:
		topic_creator.visible = false
		var database_create = "CREATE TABLE IF NOT EXISTS \"" + topic_creator_input.text + "\" (id INTEGER PRIMARY KEY AUTOINCREMENT, question TEXT, answer TEXT)"
		db.query(database_create)
		topic_selector_process()
	pass # Replace with function body.


func _on_topic_creator_cancel_pressed() -> void:
	topic_creator.visible = false
	pass # Replace with function body.

func _on_topic_1_pressed() -> void:
	topic_selected = true
	topic = topic_1.text
func _on_topic_2_pressed() -> void:
	topic_selected = true
	topic = topic_2.text
func _on_topic_3_pressed() -> void:
	topic_selected = true
	topic = topic_3.text
func _on_topic_4_pressed() -> void:
	topic_selected = true
	topic = topic_4.text


func _on_answer_submit_pressed() -> void:
	answer_input = get_node("/root/Node2D/Revision/AnswerPanel/AnswerInput")
	if answer_input.text.is_empty():
		error.visible = true
		error.text = "You Didn't input anything!"
		await get_tree().create_timer(3.0).timeout
		error.visible = false
	else:
		var answer_panel = get_node("/root/Node2D/Revision/AnswerPanel")
		answer_panel.visible = false
		user_answer = answer_input.text
		user_has_submitted_answer = true
		answer_input.text = ""
	pass # Replace with function body.


func _on_next_question_pressed() -> void:
	next_question = true
	pass # Replace with function body.
