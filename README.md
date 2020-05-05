# README

## 介绍

经历了一系列漫无目的的学习之后，我陷入过迷茫，开始怀疑自己选择完成操作系统是否可行，时间消耗如何，以及产生了一些诸如“选用哪个教程”，“这个知识点已经学过了，在这个教程还要不要看”之类的无聊问题。

感觉清华的ucore难以继续下去，主要原因是缺乏必要的实验引导。尽管从实验书、学堂在线上获取的基础知识让人受益颇多，但面对代码依然无从下手，难以理解系统代码和实验编写代码之间的调用和联系，难以理解实验加入的变量和方便实验使用的方法。基于此，决定整理进行xv6的实验。

本仓库预计分为三个部分，第一个部分进行JOS的lab，第二个部分记录xv6源码阅读过程，添加中文注释，第三个部分存放xv6课程的资源，包括slides、参考书、工具等。

第一阶段做lab，第二阶段读源码，第三阶段（maybe）写os。

这是一个长期更新的仓库，目标是借由xv6的学习经验，实现OS作为毕设。

## 更新记录

### 20200319

创建此仓库，添加了xv6源码、xv6 book的中文翻译

### 20200505

自Lab3开始，进行编译后的kernel镜像总是会出现内存映射的错误。其间换用了网上可以搜集到的已验证代码进行本地编译，结果依然出错。推测可能是编译器版本导致的优化，进而产生问题（实验环境搭建时未采用6.828页面推荐的环境配置）。出于时间原因，其后的实验均直接阅读了实验设计，部分阅读了互联网上的实验笔记。

更新至lab5。
