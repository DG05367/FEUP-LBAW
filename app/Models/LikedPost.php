<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class LikedPost extends Model
{
    use HasFactory;

    protected $table = 'liked_posts';
    public $timestamps = false;

    public function liker(){return $this->belongsTo('App\Models\User');}

    public function posts(){return $this->belongsToMany('App\Models\Post');}
}
