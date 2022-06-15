<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Comment extends Model
{
    use HasFactory;

    protected $table = 'comment';
    protected $primaryKey = 'comment_id';
    public $timestamps = false;

    public function comment_author(){return $this->belongsTo('App\Models\User', 'comment_id', 'user_id');}

    public function comment_reports(){return $this->hasMany('App\Models\ReportComment');}

    public function comment_notification(){return $this->hasOne('App\Models\Notification');}

    public function commented_post(){return $this->belongsTo('App\Models\Post');}

    public function medias(){return $this->belongsToMany('App\Models\Media');}
}
