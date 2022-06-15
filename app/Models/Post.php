<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Post extends Model
{
    use HasFactory;

    protected $primaryKey = 'post_id';
    protected $table = 'post';
    public $timestamps = false;

    public function author(){return $this->belongsTo('App\Models\User', 'author_id', 'user_id');}

    public function comments(){return $this->hasMany('App\Models\Comment', 'post_id', 'post_id');}

    public function liked_posts(){return $this->belongsToMany('App\Models\LikedPost');}

    public function medias(){return $this->belongsToMany('App\Models\Media');}

    public function notifications(){return $this->hasMany('App\Models\Notification');}

    public function report(){return $this->hasOne('App\Models\ReportPost');}

    public function tags(){return $this->belongsTo('App\Models\Tag', 'tag_id','tag_id');}
}
