from pathlib import Path
import argparse,json
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Ellipse,Rectangle,FancyArrowPatch
from matplotlib.path import Path as MPath
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
ap=argparse.ArgumentParser()
ap.add_argument('--tables',default=str(ROOT/'results/behavior/tables'))
ap.add_argument('--primary-family',default=str(ROOT/'results/primary_family'))
ap.add_argument('--out',default=str(ROOT/'figures'))
args=ap.parse_args()
T=Path(args.tables);O=Path(args.out);O.mkdir(parents=True,exist_ok=True)
family=Path(args.primary_family)/'behavioral_primary_focal.csv'
a=pd.read_csv(family if family.exists()else T/'H1_primary_focal_with_Holm.csv')
b=pd.read_csv(T/'Barrier_components_pooled_focal.csv')
assert len(a)==18 and len(b)==24 and a.n.eq(1832).all() and b.n.eq(1832).all()
order=['F_Risk','F_Coping','F_Confidence','Support','Oversight','Training','Barriers','Benefits','Norms']
names={'F_Risk':'Risk beliefs','F_Coping':'Coping self-efficacy','F_Confidence':'Safety confidence',
 'Support':'Support/resources','Oversight':'Oversight','Training':'Training recency',
 'Barriers':'Safety barriers','Benefits':'Safety benefits','Norms':'Descriptive norms',
 'C5':'Equipment cost (C5)','C6':'Heat discomfort (C6)','C7':'Time burden (C7)','C8':'Access difficulty (C8)'}
plt.rcParams.update({'font.family':'Arial','font.size':8.5,'axes.titlesize':9,
 'axes.labelsize':8.5,'xtick.labelsize':8,'ytick.labelsize':8.5,
 'savefig.facecolor':'white','pdf.fonttype':42,'svg.fonttype':'none'})
blue='#315C78';gold='#AA7417';gray='#555555'
checks=[]
def save(fig,name):
 fig.savefig(O/f'{name}.png',dpi=400,facecolor='white')
 fig.savefig(O/f'{name}.pdf',facecolor='white')
 fig.savefig(O/f'{name}.svg',facecolor='white')
 fig.savefig(O/f'{name}.tiff',dpi=400,facecolor='white',pil_kwargs={'compression':'tiff_lzw'})
 with Image.open(O/f'{name}.tiff')as im:
  im.convert('RGB').save(O/f'{name}.tiff',compression='tiff_lzw',dpi=(400,400))
 with Image.open(O/f'{name}.tiff')as im:
  checks.append({'file':name+'.tiff','pixels':list(im.size),'dpi':[float(x)for x in im.info['dpi']],
   'mode':im.mode,'frames':im.n_frames,'bytes':(O/f'{name}.tiff').stat().st_size})
 plt.close(fig)

# Fig1A groups adjustment paths; Fig1B displays all18 direct behavioral estimates.
fig=plt.figure(figsize=(7.5,8.6));d=fig.add_axes([.025,.725,.95,.23]);d.set(xlim=(0,1),ylim=(0,1));d.axis('off')
fig.text(.025,.968,'A  Hybrid measurement and behavioral specification',fontsize=9.5)
box=Rectangle((.005,.26),.245,.62,facecolor='#F4F5F6',edgecolor=gray,lw=.8)
d.add_patch(box);d.text(.1275,.57,'Six observed summaries\n\nSupport/resources\nOversight · Training\nBarriers · Benefits\nDescriptive norms',ha='center',va='center',fontsize=8.3,linespacing=1.12)
g=Rectangle((.33,.19),.34,.71,facecolor='none',edgecolor='#BEC8CE',lw=.7)
d.add_patch(g);d.text(.50,.96,'Ordinal belief factors',ha='center',va='center',fontsize=8.5)
for y,label in [(.77,'Risk beliefs\nC1–C4'),(.53,'Coping self-efficacy\nC11–C13'),(.29,'Safety confidence\nC14–C16')]:
 p=Ellipse((.50,y),.31,.20,facecolor='#EDF3F6',edgecolor=blue,lw=.9)
 d.add_patch(p);d.text(.50,y,label,ha='center',va='center',fontsize=8.2,linespacing=1.04)
outgroup=Rectangle((.77,.20),.225,.67,facecolor='none',edgecolor='#BEC8CE',lw=.7)
d.add_patch(outgroup)
for y,label in [(.68,'PPE mean score\nD1–D4'),(.40,'Handling mean score\nD5–D8')]:
 p=Rectangle((.785,y-.105),.195,.21,facecolor='#F4F5F6',edgecolor=gray,lw=.9)
 d.add_patch(p);d.text(.8825,y,label,ha='center',va='center',fontsize=8.2,linespacing=1.05)
for start,end in [((.252,.57),(.323,.57)),((.675,.55),(.765,.55))]:
 d.add_patch(FancyArrowPatch(start,end,arrowstyle='-|>',mutation_scale=9,lw=.9,color=gray))
path=MPath([(.249,.265),(.249,.13),(.885,.13),(.885,.20)],
 [MPath.MOVETO,MPath.LINETO,MPath.LINETO,MPath.LINETO])
d.add_patch(FancyArrowPatch(path=path,arrowstyle='-|>',mutation_scale=9,lw=.9,color=gray))
fig.text(.035,.714,'The six observed summaries also directly enter both practice equations.',fontsize=8.2)
fig.text(.035,.691,'Country and A1–A11 enter every equation as categorical dummy controls.',fontsize=8.3)
fig.text(.035,.674,'Belief-factor residuals freely covary; the PPE and handling residuals covary.',fontsize=8.3)
fig.text(.025,.648,'B  All direct behavioral associations (n = 1,832)',fontsize=9.5)
ax=fig.add_axes([.34,.105,.38,.515]);ax.set_axisbelow(True);ax.grid(axis='x',color='#E6E6E6',lw=.5)
ax.spines[['top','right']].set_visible(False);ax.axvline(0,color='#666666',lw=.8,ls='--')
rows=[];yvals=[];labels=[]
for oi,outcome in enumerate(['PPE','Handling']):
 for i,predictor in enumerate(order):
  r=a[(a.outcome==outcome)&(a.predictor==predictor)].iloc[0]
  y=18-i if oi==0 else 8-i
  yvals.append(y);labels.append(names[predictor]);rows.append(r)
  sig=bool(r.p_holm<.05)
  ax.errorbar(r.beta,y,xerr=[[r.beta-r.beta_ci_lower],[r.beta_ci_upper-r.beta]],fmt='o',
   ms=4.4,color=blue,mfc=blue if sig else'white',mec=blue,capsize=0,lw=.95)
  fig.text(.754,.105+.515*(y+.65)/19.35,f'{r.beta:+.3f} [{r.beta_ci_lower:+.3f}, {r.beta_ci_upper:+.3f}]',
   va='center',fontsize=8.0)
ax.set(ylim=(-.65,18.7),xlim=(-.22,.40));ax.set_yticks(yvals,labels);ax.tick_params(axis='y',length=0,pad=5)
ax.set_xticks([-.1,0,.1,.2,.3]);ax.set_xlabel('Fully standardized β with nominal 95% CI',labelpad=5)
ax.axhline(8.9,color='#BBBBBB',lw=.7)
fig.text(.030,.105+.515*(14+.65)/19.35,'PPE use',fontweight='bold',fontsize=9,va='center')
fig.text(.030,.105+.515*(4+.65)/19.35,'Chemical\nhandling',fontweight='bold',fontsize=9,va='center')
fig.text(.754,.626,'β [95% CI]',fontsize=8.3)
fig.text(.035,.041,'Filled markers: Holm-adjusted p < .05 across the joint 26-test primary family.',fontsize=8.2)
fig.text(.035,.022,'Intervals are nominal delta-method intervals; arrows and coefficients do not establish causation.',fontsize=8.0)
pd.DataFrame(rows).to_csv(O/'Fig1_plot_data.csv',index=False)
save(fig,'Fig1')

# Fig3A compares the16 common paths; Fig3B shows8 individual barrier associations.
fig=plt.figure(figsize=(7.5,8.5))
fig.text(.025,.967,'A  Common paths under the isolated barrier specification',fontsize=9.5)
ax=fig.add_axes([.345,.500,.59,.420]);ax.set_axisbelow(True);ax.grid(axis='x',color='#E6E6E6',lw=.5)
ax.spines[['top','right']].set_visible(False);ax.axvline(0,color='#666666',lw=.8,ls='--')
keep=[x for x in order if x!='Barriers'];ys=[];labs=[];plotrows=[]
for oi,outcome in enumerate(['PPE','Handling']):
 for i,predictor in enumerate(keep):
  y=16-i if oi==0 else 7-i
  ys.append(y);labs.append(names[predictor])
  r=a[(a.outcome==outcome)&(a.predictor==predictor)].iloc[0]
  s=b[(b.lhs==outcome)&(b.rhs==predictor)].iloc[0]
  for k,col,marker,offset,label in [(r,blue,'o',.11,'Main SEM'),(s,gold,'^',-.11,'Individual-barrier model')]:
   ax.errorbar(k.beta,y+offset,xerr=[[k.beta-k.beta_ci_lower],[k.beta_ci_upper-k.beta]],fmt=marker,
    ms=4.2,color=col,mfc=col,mec=col,lw=.9,capsize=0,label=label if oi==0 and i==0 else None)
  plotrows.extend([{'panel':'A','outcome':outcome,'predictor':predictor,'model':'Main SEM',
   'beta':r.beta,'lower':r.beta_ci_lower,'upper':r.beta_ci_upper},
   {'panel':'A','outcome':outcome,'predictor':predictor,'model':'Individual-barrier model',
   'beta':s.beta,'lower':s.beta_ci_lower,'upper':s.beta_ci_upper}])
ax.set(ylim=(-.65,16.7),xlim=(-.19,.40));ax.set_yticks(ys,labs);ax.tick_params(axis='y',length=0,pad=5)
ax.set_xticks([-.1,0,.1,.2,.3]);ax.set_xlabel('Fully standardized β with nominal 95% CI',labelpad=5)
ax.axhline(7.9,color='#BBBBBB',lw=.7)
ax.legend(loc='lower left',bbox_to_anchor=(-.02,1.00),frameon=False,ncol=2,fontsize=8.2,
 handletextpad=.4,columnspacing=1.2)
fig.text(.028,.500+.420*(12.5+.65)/17.35,'PPE use',fontweight='bold',fontsize=9,va='center')
fig.text(.028,.500+.420*(3.5+.65)/17.35,'Chemical\nhandling',fontweight='bold',fontsize=9,va='center')
fig.text(.035,.432,'Same respondents and adjustment set; Training and Norms retain their primary definitions.',fontsize=8.1)
fig.text(.035,.411,'Overlapping-model intervals are shown descriptively; coefficient-difference tests are not implied.',fontsize=8.0)
fig.text(.025,.377,'B  Individual barrier associations in the sensitivity model',fontsize=9.5)
ax=fig.add_axes([.345,.110,.59,.235]);ax.set_axisbelow(True);ax.grid(axis='x',color='#E6E6E6',lw=.5)
ax.spines[['top','right']].set_visible(False);ax.axvline(0,color='#666666',lw=.8,ls='--')
ys=[];labs=[]
for oi,outcome in enumerate(['PPE','Handling']):
 for i,predictor in enumerate(['C5','C6','C7','C8']):
  r=b[(b.lhs==outcome)&(b.rhs==predictor)].iloc[0];y=8-i if oi==0 else 3-i
  ys.append(y);labs.append(names[predictor])
  ax.errorbar(r.beta,y,xerr=[[r.beta-r.beta_ci_lower],[r.beta_ci_upper-r.beta]],fmt='o',ms=4.2,
   color=gold,mfc=gold,mec=gold,lw=.9,capsize=0)
  plotrows.append({'panel':'B','outcome':outcome,'predictor':predictor,'model':'Individual-barrier model',
   'beta':r.beta,'lower':r.beta_ci_lower,'upper':r.beta_ci_upper})
ax.set(ylim=(-.65,8.65),xlim=(-.225,.115));ax.set_yticks(ys,labs);ax.tick_params(axis='y',length=0,pad=5)
ax.set_xticks([-.2,-.1,0,.1]);ax.set_xlabel('Fully standardized β with nominal 95% CI',labelpad=5)
ax.axhline(3.9,color='#BBBBBB',lw=.7)
fig.text(.028,.110+.235*(6.5+.65)/9.3,'PPE use',fontweight='bold',fontsize=9,va='center')
fig.text(.028,.110+.235*(1.5+.65)/9.3,'Chemical\nhandling',fontweight='bold',fontsize=9,va='center')
fig.text(.035,.030,'All sensitivity intervals are nominal; sensitivity tests are exploratory and unadjusted.',fontsize=8.2)
pd.DataFrame(plotrows).to_csv(O/'Fig3_plot_data.csv',index=False)
save(fig,'Fig3')
(O/'figure_technical_checks.json').write_text(json.dumps(checks,indent=2)+'\n')
print(json.dumps(checks,indent=2))
