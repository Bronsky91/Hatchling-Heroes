extends Node2D

var score_row = preload("res://Scenes/ScoreRow.tscn")
var top_hundred = 0

func _ready():
	$GameJoltAPI.connect("api_scores_fetched", self, '_on_scores_fetched')
	$GameJoltAPI.fetch_scores()

func _on_scores_fetched(data):
	var first_place = true
	var score_data = JSON.parse(data).result
	for score in score_data.response.scores:
		var new_score_row = score_row.instance()
		new_score_row.get_node('Rank').text = score.score
		new_score_row.get_node("CreatureName").text = score.guest
		g.load_creature(new_score_row.get_node("BodyContainer/Body"), score.extra_data)
		if first_place:
			new_score_row.get_node("BodyContainer/Body/Hat").show()
		$ScrollContainer/VBoxContainer.add_child(new_score_row)
		top_hundred += 1
		first_place = false
		if top_hundred == 100:
			break
