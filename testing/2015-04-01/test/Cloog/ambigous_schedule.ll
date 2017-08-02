; RUN: opt %loadPolly -basicaa -polly-import-jscop-dir=%S -polly-import-jscop -polly-cloog -analyze < %s | FileCheck %s
target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@A = common global [100 x [100 x double]] zeroinitializer, align 16
@B = common global [100 x [100 x double]] zeroinitializer, align 16

define void @ambigous_schedule() nounwind uwtable {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc6, %entry
  %i.0 = phi i32 [ 0, %entry ], [ %inc7, %for.inc6 ]
  %cmp = icmp slt i32 %i.0, 100
  br i1 %cmp, label %for.body, label %for.end8

for.body:                                         ; preds = %for.cond
  br label %for.cond1

for.cond1:                                        ; preds = %for.inc, %for.body
  %j.0 = phi i32 [ 0, %for.body ], [ %inc, %for.inc ]
  %cmp2 = icmp slt i32 %j.0, 100
  br i1 %cmp2, label %for.body3, label %for.end

for.body3:                                        ; preds = %for.cond1
  %add = add nsw i32 %i.0, %j.0
  %conv = sitofp i32 %add to double
  %idxprom = sext i32 %j.0 to i64
  %idxprom4 = sext i32 %i.0 to i64
  %arrayidx = getelementptr inbounds [100 x [100 x double]]* @A, i32 0, i64 %idxprom4
  %arrayidx5 = getelementptr inbounds [100 x double]* %arrayidx, i32 0, i64 %idxprom
  store double %conv, double* %arrayidx5, align 8
  br label %for.inc

for.inc:                                          ; preds = %for.body3
  %inc = add nsw i32 %j.0, 1
  br label %for.cond1

for.end:                                          ; preds = %for.cond1
  br label %for.inc6

for.inc6:                                         ; preds = %for.end
  %inc7 = add nsw i32 %i.0, 1
  br label %for.cond

for.end8:                                         ; preds = %for.cond
  br label %for.cond10

for.cond10:                                       ; preds = %for.inc28, %for.end8
  %i9.0 = phi i32 [ 0, %for.end8 ], [ %inc29, %for.inc28 ]
  %cmp11 = icmp slt i32 %i9.0, 100
  br i1 %cmp11, label %for.body13, label %for.end30

for.body13:                                       ; preds = %for.cond10
  br label %for.cond15

for.cond15:                                       ; preds = %for.inc25, %for.body13
  %j14.0 = phi i32 [ 0, %for.body13 ], [ %inc26, %for.inc25 ]
  %cmp16 = icmp slt i32 %j14.0, 100
  br i1 %cmp16, label %for.body18, label %for.end27

for.body18:                                       ; preds = %for.cond15
  %add19 = add nsw i32 %i9.0, %j14.0
  %conv20 = sitofp i32 %add19 to double
  %idxprom21 = sext i32 %j14.0 to i64
  %idxprom22 = sext i32 %i9.0 to i64
  %arrayidx23 = getelementptr inbounds [100 x [100 x double]]* @B, i32 0, i64 %idxprom22
  %arrayidx24 = getelementptr inbounds [100 x double]* %arrayidx23, i32 0, i64 %idxprom21
  store double %conv20, double* %arrayidx24, align 8
  br label %for.inc25

for.inc25:                                        ; preds = %for.body18
  %inc26 = add nsw i32 %j14.0, 1
  br label %for.cond15

for.end27:                                        ; preds = %for.cond15
  br label %for.inc28

for.inc28:                                        ; preds = %for.end27
  %inc29 = add nsw i32 %i9.0, 1
  br label %for.cond10

for.end30:                                        ; preds = %for.cond10
  ret void
}

; CHECK: for (c2=0;c2<=99;c2++) {
; CHECK:   for (c3=0;c3<=99;c3++) {
; CHECK:     Stmt_for_body3(c2,c3);
; CHECK:     Stmt_for_body18(c3,c2);
; CHECK:   }
; CHECK: }

; This check makes sure CLooG stops splitting for ambiguous schedules as
; they may be generated by the isl/PoCC/Pluto schedule optimizers.
;
; Previously we created such code:
;
; for (c2=0;c2<=99;c2++) {
;   for (c3=0;c3<=99;c3++) {
;     if (c2 == c3) {
;       Stmt_for_body3(c2,c2);
;       Stmt_for_body18(c2,c2);
;     }
;     if (c2 <= c3-1) {
;       Stmt_for_body3(c2,c3);
;     }
;     if (c2 <= c3-1) {
;       Stmt_for_body18(c3,c2);
;     }
;     if (c2 >= c3+1) {
;       Stmt_for_body18(c3,c2);
;     }
;     if (c2 >= c3+1) {
;       Stmt_for_body3(c2,c3);
;     }
;   }
; }