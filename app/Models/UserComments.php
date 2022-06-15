<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserComments extends Model
{
    use HasFactory;

    protected $table = 'user_comments';
    public $timestamps = false;

    // public function followed(){return $this->belongsToMany('App\Models\User');}
}
