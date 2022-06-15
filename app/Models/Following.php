<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Following extends Model
{
    use HasFactory;

    protected $table = 'following';
    public $timestamps = false;

    public function followed(){return $this->belongsToMany('App\Models\AuthenticatedUser');}
}
