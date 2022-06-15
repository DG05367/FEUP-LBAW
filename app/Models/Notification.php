<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Notification extends Model
{
    use HasFactory;

    protected $table = 'notification';
    public $timestamps = false;

    public function notified(){return $this->belongsTo('App\Models\User');}

    public function comment_notification(){return $this->belongsTo('App\Models\Comment');}

    public function post_notification(){return $this->belongsTo('App\Models\Post');}
}