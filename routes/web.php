<?php

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/
// Home
Route::get('/', 'Auth\LoginController@home');

// Cards
// Route::get('cards', 'CardController@list');
// Route::get('cards/{id}', 'CardController@show');

// API
// Route::put('api/cards', 'CardController@create');
// Route::delete('api/cards/{card_id}', 'CardController@delete');
// Route::put('api/cards/{card_id}/', 'ItemController@create');
// Route::post('api/item/{id}', 'ItemController@update');
// Route::delete('api/item/{id}', 'ItemController@delete');

// Authentication
Route::get('login', 'Auth\LoginController@showLoginForm')->name('login');
Route::post('login', 'Auth\LoginController@login');
Route::get('logout', 'Auth\LoginController@logout')->name('logout');
Route::get('register', 'Auth\RegisterController@showRegistrationForm')->name('register');
Route::post('register', 'Auth\RegisterController@register');

// Static Pages
Route::view('/about', 'pages.about');
Route::view('/services', 'pages.services');
Route::view('/faq', 'pages.faq');
Route::view('/contact', 'pages.contact');
Route::view('/404', 'pages.404');

Route::get('/home', 'PostController@index');
Route::get('/post/{id}', 'PostController@post');

Route::get('/tag/{id}', 'PostController@posts_with_tag');

Route::get('/profile/{id}', 'ProfileController@posts');
Route::get('/profile/{id}/posts', 'ProfileController@posts');
Route::get('/profile/{id}/comments', 'ProfileController@comments');
Route::get('/profile/{id}/likes', 'ProfileController@likes');

Route::get('/profile/tab1', function(){return view('HELLO WORLD 1');});
Route::get('/profile/tab2', function(){return view('HELLO WORLD 2');});
Route::get('/profile/tab3', function(){return view('HELLO WORLD 3');});