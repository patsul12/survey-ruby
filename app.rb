require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/activerecord'
also_reload('./**/*.rb')
require 'pg'
require './lib/survey'
require './lib/question'
require './lib/response'
require "pry"

set :public, 'public'
get '/' do
  @surveys = Survey.all()

  erb :index
end

post '/surveys' do
  title = params[:title]
  survey = Survey.create(title: title)

  redirect("/surveys/#{survey.id}")
end

get '/surveys/:id' do
  @survey = Survey.find(params[:id])
  @questions = @survey.questions
  @counter = 2
  erb :survey_form
end

patch '/surveys/:id' do
  @survey = Survey.find(params[:id])
  @survey.update(title: params[:title])
  redirect "/surveys/#{@survey.id}"
end

delete '/surveys/:id' do
  survey = Survey.find(params[:id])
  survey.destroy
  redirect "/"
end

get '/surveys/:id/questionnaire' do
  @survey = Survey.find(params[:id])
  @questions = @survey.questions
  erb :questionnaire
end

post '/surveys/:id/questions' do
  survey = Survey.find(params[:id])
  question = survey.questions.create(question: params[:question])

  params[:response_count].to_i.times do |count|
    response_number = "response" << (count + 1).to_s
    question.responses.create(response: params[response_number.to_sym])
  end

  redirect("/surveys/#{survey.id}")
end

post '/surveys/:id/responses' do
  survey = Survey.find(params[:id])
  questions = survey.questions

  questions.each do |question|
    choice_id = params["#{question.id}".to_sym]
    choice = Response.find(choice_id)
    choice_counter = choice.counter + 1
    choice.update(counter: choice_counter)
  end

  redirect "/surveys/#{survey.id}/results"
end

get '/surveys/:id/results' do
  @survey = Survey.find(params[:id])
  @questions = @survey.questions

  @total_responses = 0
  @questions.first.responses.each do |response|
    @total_responses += response.counter
  end

  erb :results
end

get '/questions/:id' do
  @question = Question.find(params[:id])
  @responses = @question.responses
  erb :question
end

patch '/questions/:id' do
  question = Question.find(params[:id])
  question.update(question: params[:question])
  existing_responses = question.responses

  existing_responses.each() do |response|
    response.update(response: params["#{response.id}".to_sym])
  end

  params[:response_count].to_i.times do |count|
    response_number = "response" << (count + 1).to_s
    question.responses.create(response: params[response_number.to_sym])
  end

  redirect "/questions/#{question.id}"
end

delete '/questions/:id' do
  question = Question.find(params[:id])
  survey_id = question.survey.id
  question.destroy

  redirect("/surveys/#{survey_id}")
end

delete '/responses/:response_id' do
  response = Response.find(params[:response_id])
  question_id = response.question.id
  response.destroy
  redirect "/questions/#{question_id}"
end
